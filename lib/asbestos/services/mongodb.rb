
#
# the mongo shard routing server
#
service :mongos do
  port 27017
end

#
# mongod running as a shard server
#
service :mongodb_shard do
  port 27018
end

#
# mongod running as a config server
#
service :mongodb_config do
  port 27019
end

#
# standard mongodb server
#
service :mongodb do
  port 27017
end
