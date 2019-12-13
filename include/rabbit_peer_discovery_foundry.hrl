% If a setting is not defined (absent from envvar and rabbitmq.conf) then the default
% defined here is used. If the setting is defined in rabbitmq.conf then that value is
% used. If the envvar is defined, then that value is used. Default -> conf -> env.
%
% NOTE: In order to reload these values, you need to restart the rabbitmq server.
% A rabbitmqctl stop_app / reset / start_app is not sufficient. These values load
% once at process start and a rabbitmqctl-invoked cycle is not enough to reload them.
-define(CONFIG_MAPPING,
         #{
          foundry_scheme                         => #peer_discovery_config_entry_meta{
                                                   type          = string,
                                                   env_variable  = "FOUNDRY_PEER_DISCOVER_SCHEME",
                                                   default_value = "http"
                                                  },
          foundry_host                           => #peer_discovery_config_entry_meta{
                                                   type          = string,
                                                   env_variable  = "FOUNDRY_PEER_DISCOVER_HOST",
                                                   default_value = "localhost"
                                                  },
          foundry_port                           => #peer_discovery_config_entry_meta{
                                                   type          = integer,
                                                   env_variable  = "FOUNDRY_PEER_DISCOVER_PORT",
                                                   default_value = 8889 
                                                  },
          foundry_plugin                          => #peer_discovery_config_entry_meta{
                                                   type          = string,
                                                   env_variable  = "FOUNDRY_PEER_DISCOVER_PLUGINNAME",
                                                   default_value = "com.hitachi.aspen.foundry.service.rabbitmq.server"
                                                  }
         }).
