require 'aws-sdk'
require 'httparty'
require 'json'

ec2_prices = Hash.new
['mswin', 'linux'].each do |os|

  prices_url = HTTParty.get("https://a0.awsstatic.com/pricing/1/deprecated/ec2/#{os}-od.json")
  prices = JSON.parse(prices_url.body)
  ireland = prices['config']['regions'][3]['instanceTypes'] if prices['config']['regions'][3]['region'] == 'eu-ireland'

  ec2_prices[os] = Hash.new
  ireland.each do |i|
    i['sizes'].each do |s|
      ec2_prices[os][s['size']] = s['valueColumns'][0]['prices']['USD']
    end
  end
end

ec2 = AWS::EC2.new


SCHEDULER.every '30s' do
  current_cost = 0

  ec2.instances.each do |i|
    if i.platform == 'windows'
      current_cost += ec2_prices['mswin'][i.instance_type].to_f if i.status == :running
    else
      current_cost += ec2_prices['linux'][i.instance_type].to_f if i.status == :running
    end
  end

  send_event('running_ec2_cost', { current: current_cost.round(2) * 24 })
end
