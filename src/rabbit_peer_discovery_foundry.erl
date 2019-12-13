%% The contents of this file are subject to the Mozilla Public License
%% Version 1.1 (the "License"); you may not use this file except in
%% compliance with the License. You may obtain a copy of the License at
%% https://www.mozilla.org/MPL/
%%
%% Software distributed under the License is distributed on an "AS IS"
%% basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
%% License for the specific language governing rights and limitations
%% under the License.
%%
%% The Original Code is RabbitMQ.
%%
%% The Initial Developer of the Original Code is AWeber Communications.
%% Copyright (c) 2015-2016 AWeber Communications
%% Copyright (c) 2016-2017 Pivotal Software, Inc. All rights reserved.
%%

-module(rabbit_peer_discovery_foundry).
-behaviour(rabbit_peer_discovery_backend).

-include_lib("rabbit_common/include/rabbit.hrl").
-include_lib("rabbitmq_peer_discovery_common/include/rabbit_peer_discovery.hrl").
-include("rabbit_peer_discovery_foundry.hrl").

-export([init/0, list_nodes/0, supports_registration/0, register/0, unregister/0,
         post_registration/0, lock/1, unlock/1, randomized_startup_delay_range/0]).

-ifdef(TEST).
-compile(export_all).
-endif.

-define(CONFIG_MODULE, rabbit_peer_discovery_config).
-define(UTIL_MODULE,   rabbit_peer_discovery_util).
-define(HTTPC_MODULE,  rabbit_peer_discovery_httpc).

-define(BACKEND_CONFIG_KEY, peer_discovery_foundry).
-define(CONTENT_JSON, "application/json").
-define(FOUNDRY_SERVICE_QUERY, "{ \"requestedDetails\" : [ \"serviceInstance\" ]}").

%%
%% API
%%

init() ->
    rabbit_log:debug("Peer discovery Foundry: initialising..."),
    ok = application:ensure_started(inets),
    %% we cannot start this plugin yet since it depends on the rabbit app,
    %% which is in the process of being started by the time this function is called
    application:load(rabbitmq_peer_discovery_common),
    rabbit_peer_discovery_httpc:maybe_configure_proxy().

-spec list_nodes() -> {ok, {Nodes :: list(), NodeType :: rabbit_types:node_type()}}.

list_nodes() ->
    %% List all of the foundry services
    case make_services_request() of
	{ok, ServiceResponse} ->
            %% Find all of the rabbitmq instance uuids
            rabbit_log:debug("ServiceResponse - ~s", [ServiceResponse]),
	    InstanceUuids = extract_instance_uuids(ServiceResponse),

            rabbit_log:info("Instances - ~s", [InstanceUuids]),

            %% List all of the foundry instances (nodes)
            case make_instances_request() of
                {ok, InstanceResponse} ->
                    %% Get the instance IP address for all of the rabbitmq instances
                    rabbit_log:debug("Instance Response - ~s", [InstanceResponse]),
                    Addresses = extract_instance_ips(InstanceResponse, InstanceUuids),
                    rabbit_log:info("Addresses - ~s", [Addresses]),
                    {ok, lists:map(fun node_name/1, Addresses)};
                {error, Reason} ->
                    rabbit_log:info(
                      "Failed to get instances from foundry - ~s", [Reason]),
                    {error, Reason}
            end;
	{error, Reason} ->
	    rabbit_log:info(
	      "Failed to get services from foundry - ~s", [Reason]),
	    {error, Reason}
    end.

-spec supports_registration() -> boolean().

supports_registration() ->
    false.


-spec register() -> ok.
register() ->
    ok.

-spec unregister() -> ok.
unregister() ->
    ok.

-spec post_registration() -> ok | {error, Reason :: string()}.

post_registration() ->
    ok.

-spec lock(Node :: atom()) -> not_supported.

lock(_Node) ->
    not_supported.

-spec unlock(Data :: term()) -> ok.

unlock(_Data) ->
    ok.

-spec randomized_startup_delay_range() -> {integer(), integer()}.

randomized_startup_delay_range() ->
    %% Pods in a stateful set are initialized one by one,
    %% so RSD is not really necessary for this plugin.
    %% See https://www.rabbitmq.com/cluster-formation.html#peer-discovery-k8s for details.
    {0, 2}.

%%
%% Implementation
%%

%% @private
%% @doc get a configuration key
%% @end
%%
-spec get_config_key(Key :: atom(), Map :: #{atom() => peer_discovery_config_value()})
                    -> peer_discovery_config_value().

get_config_key(Key, Map) ->
    ?CONFIG_MODULE:get(Key, ?CONFIG_MAPPING, Map).

%% @private
%% @doc Perform a HTTP POST request to foundry /services
%% @end
%%
-spec make_services_request() -> {ok, term()} | {error, term()}.
make_services_request() ->
    M = ?CONFIG_MODULE:config_map(?BACKEND_CONFIG_KEY),
    URL = rabbit_peer_discovery_httpc:build_uri(get_config_key(foundry_scheme, M),
                                                get_config_key(foundry_host, M),
                                                get_config_key(foundry_port, M),
                                                ["api", "foundry", "services", "query"],
                                                []),
    rabbit_log:info("services request endpoint: ~s", [URL]),
    Response = httpc:request(post, {URL, [{"Accept","application/json"}], "application/json", "{ \"requestedDetails\" : [ \"serviceInstances\" ]}"}, [], []),
    parse_response(Response).

%% @private
%% @doc Perform a HTTP POST request to foundry /instances
%% @end
%%
-spec make_instances_request() -> {ok, term()} | {error, term()}.
make_instances_request() ->
    M = ?CONFIG_MODULE:config_map(?BACKEND_CONFIG_KEY),
    URL = rabbit_peer_discovery_httpc:build_uri(get_config_key(foundry_scheme, M),
                                                get_config_key(foundry_host, M),
                                                get_config_key(foundry_port, M),
                                                ["api", "foundry", "instances"],
                                                []),
    rabbit_log:info("instances request endpoint: ~s", [URL]),
    Response = httpc:request(get, {URL, [{"Accept","application/json"}]}, [], []),
    parse_response(Response).

%% @spec node_name(foundry instance) -> list()  
%% @doc Return a full rabbit node name
%% @end
%%
node_name(Address) ->
    ?UTIL_MODULE:node_name(?UTIL_MODULE:as_string(Address)).

%% @private
%% @doc Return a list of instance uuids
%%    see http://kubernetes.io/docs/api-reference/v1/definitions/#_v1_endpoints
%% @end
%%
-spec extract_instance_uuids(term()) -> [binary()].
extract_instance_uuids(Response) ->
    M = ?CONFIG_MODULE:config_map(?BACKEND_CONFIG_KEY),
    P = get_config_key(foundry_plugin, M),
    rabbit_log:info("extract_instance_uuids searching for plugin: ~p~n", [P]),
    rabbit_log:debug("Response: ~p~n", [Response]),
    %% Get the list of services from the response
    ServiceConfigs = maps:get(<<"serviceConfigs">>, Response, []),
    rabbit_log:debug("ServiceConfigs: ~p~n", [ServiceConfigs]),
    %% Create a list of rabbit mq services (should really only be 1 element)
    RabbitMQService = lists:filter(fun(S) -> PluginName = maps:get(<<"pluginName">>, S),
                                             string:equal(PluginName, P) end,
                                   ServiceConfigs),
    rabbit_log:debug("RabbitMQService: ~p~n", [RabbitMQService]),
    %% Get the service instances for the rabbitmq services
    ServiceInstances = lists:map(fun(S) -> maps:get(<<"serviceInstances">>, S, []) end, RabbitMQService),
    rabbit_log:debug("ServiceInstances: ~p~n", [ServiceInstances]),
    %% Flatten the lists of lists into a single list
    FlatServiceInstances = lists:flatten(ServiceInstances),
    rabbit_log:debug("FlatServiceInstances: ~p~n", [FlatServiceInstances]),
    %% Get the instance uuids for each of the service instances
    lists:map(fun(S) -> maps:get(<<"instanceUuid">>, S, []) end, FlatServiceInstances).

extract_instance_ips(Response, InstanceUuids) ->
    rabbit_log:debug("Response: ~p~n", [Response]),
    rabbit_log:debug("InstanceUuids: ~p~n", [InstanceUuids]),
    %% Get a list of the instances matching the uuids
    Instances = lists:filter(fun(I) -> InstanceUuid = maps:get(<<"uuid">>, I),
                                       rabbit_log:debug("InstanceUuid: ~p~n", [InstanceUuid]),
                                       lists:member(InstanceUuid, InstanceUuids) end, Response),
    %% Get a list of ip address for all of the instances
    lists:map(fun(I) -> maps:get(<<"ipAddress">>, I) end, Instances).

%% @private
%% @spec decode_body(mixed) -> list()
%% @doc Decode the response body and return a list
%% @end
%%
decode_body(_, []) -> [];
decode_body(?CONTENT_JSON, Body) ->
    case rabbit_json:try_decode(rabbit_data_coercion:to_binary(Body)) of
        {ok, Value} -> Value;
        {error, Err}  ->
            rabbit_log:error("HTTP client could not decode a JSON payload "
                                  "(JSON parser returned an error): ~p.~n",
                                  [Err]),
            {ok, []}
    end.

%% @private
%% @spec parse_response(Response) -> {ok, string()} | {error, mixed}
%% @where Response = {status_line(), headers(), Body} | {status_code(), Body}
%% @doc Decode the response body and return a list
%% @end
%%
parse_response({error, Reason}) ->
  rabbit_log:debug("HTTP Error ~p", [Reason]),
  {error, lists:flatten(io_lib:format("~p", [Reason]))};

parse_response({ok, 200, Body})  -> {ok, decode_body(?CONTENT_JSON, Body)};
parse_response({ok, 201, Body})  -> {ok, decode_body(?CONTENT_JSON, Body)};
parse_response({ok, 204, _})     -> {ok, []};
parse_response({ok, Code, Body}) ->
  rabbit_log:debug("HTTP Response (~p) ~s", [Code, Body]),
  {error, integer_to_list(Code)};

parse_response({ok, {{_,200,_},Headers,Body}}) ->
  {ok, decode_body(proplists:get_value("content-type", Headers, ?CONTENT_JSON), Body)};
parse_response({ok,{{_,201,_},Headers,Body}}) ->
  {ok, decode_body(proplists:get_value("content-type", Headers, ?CONTENT_JSON), Body)};
parse_response({ok,{{_,204,_},_,_}}) -> {ok, []};
parse_response({ok,{{_Vsn,Code,_Reason},_,Body}}) ->
  rabbit_log:debug("HTTP Response (~p) ~s", [Code, Body]),
  {error, integer_to_list(Code)}.
