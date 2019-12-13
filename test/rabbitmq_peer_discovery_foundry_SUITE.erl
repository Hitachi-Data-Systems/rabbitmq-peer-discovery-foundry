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

-module(rabbitmq_peer_discovery_foundry_SUITE).

-compile(export_all).
-include_lib("common_test/include/ct.hrl").
-include_lib("eunit/include/eunit.hrl").
-include("rabbit_peer_discovery_foundry.hrl").
-include_lib("rabbit_common/include/rabbit.hrl").
-include_lib("rabbitmq_peer_discovery_common/include/rabbit_peer_discovery.hrl").

all() ->
    [
     {group, unit}
    ].

groups() ->
    [
     {unit, [], [
                 extract_instance_uuids_test,
                 extract_instance_ips_test
                ]}].

init_per_testcase(T, Config) when T == node_name_empty_test;
                                  T == node_name_suffix_test ->
    meck:new(net_kernel, [passthrough, unstick]),
    meck:expect(net_kernel, longnames, fun() -> true end),
    Config;
init_per_testcase(_, Config) ->
    Config.

end_per_testcase(_, _Config) ->
    meck:unload(),
    application:unset_env(rabbit, cluster_formation),
    [os:unsetenv(Var) || Var <- ["FOUNDRY_HOSTNAME_SUFFIX",
                                 "FOUNDRY_ADDRESS_TYPE"]].

%%%
%%% Testcases
%%%

extract_instance_uuids_test(_Config) ->
    R = maps:get(foundry_plugin, ?CONFIG_MAPPING),
    P = R#peer_discovery_config_entry_meta.default_value,
    {ok, Response} =
	rabbit_json:try_decode(
          rabbit_data_coercion:to_binary(
            "{\"serviceConfigs\": [ { \"pluginName\" : \"com.hds.analytics.foundry.plugin.pipelinedeployment\", \"serviceInstances\": [ { \"instanceUuid\": \"18e22922-d4e0-49ee-bd58-db4ed5a533f0\" } ] }, { \"pluginName\" : \"" ++ P ++ "\", \"serviceInstances\": [ { \"instanceUuid\": \"dc226cd1-d001-4e6b-93c7-9a3c8502cb0b\" } ] } ] }")),
    Expectation = [<<"dc226cd1-d001-4e6b-93c7-9a3c8502cb0b">>],
    ?assertEqual(Expectation, rabbit_peer_discovery_foundry:extract_instance_uuids(Response)).

extract_instance_ips_test(_Config) ->
    {ok, Response} =
	rabbit_json:try_decode(
          rabbit_data_coercion:to_binary(
            "[ { \"uuid\" : \"1c89ab19-c41b-46e0-b348-d1ac5a929fba\", \"ipAddress\" : \"1.2.3.4\" }, { \"uuid\" : \"7439df77-5beb-4f4c-81e8-6e53672c22fb\", \"ipAddress\" : \"5.6.7.8\" } ]")),
    Expectation = [<<"1.2.3.4">>],
    ?assertEqual(Expectation, rabbit_peer_discovery_foundry:extract_instance_ips(Response, [<<"1c89ab19-c41b-46e0-b348-d1ac5a929fba">>])).