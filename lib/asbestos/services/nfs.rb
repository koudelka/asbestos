
service :nfs do
  ports :nfs, :sunrpc
  protocols :udp, :tcp
end
