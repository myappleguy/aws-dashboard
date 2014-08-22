require 'aws-sdk'

ec2 = AWS::EC2.new

SCHEDULER.every '30s' do
  instances = ec2.instances
  total = instances.count

  running = 0
  instances.each do |i|
    running+=1 if i.status == :running
  end

  send_event('running_instances', { value: running, max: total })
end
