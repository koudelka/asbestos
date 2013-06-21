
#
# the cube metrics collector and evaluator
# https://github.com/square/cube
#
service :cube_collector do
  ports 1080, 1180
  protocols [:tcp, :udp]
end

service :cube_evaluator do
  ports 1081
  protocols [:tcp]
end
