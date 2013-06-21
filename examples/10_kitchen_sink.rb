#
# This is just a large contrived example. :)
#

address :the_office, "1.2.3.4"



host_template "squidco_host" do
  interface :loopback, :lo0
  interface :internal, :bond0
  interface :external, :bond1

  accept_from_self
  allow_related_established
  icmp_protection allowed_from: :the_office
  sanity_check

  runs :ssh, on: :internal, port: 22022
  runs :ssh, on: :external, port: 22022, from: :the_office
  runs :monit, on: :external, from: :the_office
end

host_template "vps_host" do
  interface :external, :eth0

  runs :ssh, on: :external, port: 22022
  runs :worker_status, on: :external, from: :the_office
end



service :worker_status do
  port 1337
end



2.times do |i|
  squidco_host "loadbalancer_#{i}" do
    group :loadbalancers

    runs :http, on: :external
  end
end

5.times do |i|
  squidco_host "app_#{i}" do
    group :app_hosts

    runs :http, on: :internal, from: {:loadbalancers => :internal}
    runs :http, on: :external, from: :the_office
  end
end

3.times do |i|
  squidco_host "db_#{i}" do
    group :db_hosts

    runs :mongodb, on: :internal, from: {:app_hosts  => :internal}
  end
end

squidco_host "background_queue" do
  runs :redis, on: :external, from: [:the_office, {:background_workers => :external}]
end

5.times do |i|
  vps_host "worker_#{i}" do
    group :background_workers
  end
end
