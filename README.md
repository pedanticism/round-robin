# round-robin
Demonstrate how to deploy a pair of Node.js webapp servers behind a load balancer in a round-robin configuration.

## Architecture

The basic architecture consists of two EC2 instances stood up in an AWS Default VPC, 
behind an application load balancer. The instances are split between two different availability
zones to guarantee high availability in the event of a failure of an AZ. In this case the
ALB will continue to direct traffic to the instance(s) in the remaining AZ.

The EC2 instances are instantiated using a launch template and an autoscaling group. The launch
template is configured to use the latest build of the AMI into which the node.js web 
application has been baked. In the event of a failure in the AZ or if the number of instances 
is scaled up the new instances will all have the latest version of the code running on them.

The AWS infrastructure is all defined using terraform code, in the `./terraform` folder.

Note that the instances are not set up with SSH key pairs. SSM Session manager
is configured to allow a user to 
create a session on the machines if any
troubleshooting is required.

## AMI Build
In the earlier iterations of the code the Instances were provisioned using a block
of userdata passed into the `launchInstance()` call. While this was workable, the mechanism
was cumbersome for delivering code updates to the Node.js code or the application's 
configuration. The EC2 metadata service is not designed for the transmission of large
volumes of data beyond basic scripting commands, or very rudimentary code packages. 
Once the principle was proven, it was necessary
to bake the data into an AMI and use that as the unit of deployment. Packer is a much more 
powerful tool for such a task.

The Node.JS code is deployed to the instance using a file provisioner. To ensure that 
the application starts as expected when the instance starts a unit file (`nodeapp.service`) 
is also installed
which systemd uses to start the node runtime and keep it running. The unit file is also
used to inject environment variables into the node runtime in order to
demonstrate when the underlying code or AMI has changed.

## Continuous Integration
Travis was chosen as a free option with a relatively fast ramp-up time. AWS code build
would also have served.
The `.travis.yml` file shows the main elements of the build configuration: Installing the 
Python runtime and AWS libraries needed for elements of the AWS automation; Installing the node runtimes needed to execute the tests; Downloading and installing the Hashicorp Packer and Terraform binaries needed by the build.

The CI process itself is simple. All of the source code is stored in a single repository.
A git webhook triggers the build when anything is pushed to the repo. Packer builds an AMI,
Terraform updates the launch template with a new version that references the updated AMI.
At this stage the AMI is not actually deployed into the ASG. To trigger the updates of the EC2s
a Python script `scale_up_and_down.py` temporarily doubles the number of instances from two 
to four. The new instances will be spawned using the latest version of the AMI.
When all four are running it scales the instances back down to two again. The default 
termination rules will terminate the older instances with the old code. All traffic is
managed seamlessly by the load balancer.

## Testing the results
Run the following command while the build is running. NB The ALB URL will change each time the environment is torn down.

```bash
for i in {1..100}; do curl http://alb-1283622149.eu-west-1.elb.amazonaws.com/; sleep 5s; echo ;done;
```
You will see when the new EC2s with the new AMI version are brought into service and the old ones torn down.

```html
<HTML><BODY><P>Hi there! I'm being served from ip-172-31-9-166</P><P>AMI built from commit814d1293e6b73a8810435611c49a52a6033c3545</P><P>Travis build numbercundefined</P></BODY></HTML>
<HTML><BODY><P>Hi there! I'm being served from ip-172-31-46-36</P><P>AMI built from commit814d1293e6b73a8810435611c49a52a6033c3545</P><P>Travis build numbercundefined</P></BODY></HTML>
<HTML><BODY><P>Hi there! I'm being served from ip-172-31-9-166</P><P>AMI built from commit814d1293e6b73a8810435611c49a52a6033c3545</P><P>Travis build numbercundefined</P></BODY></HTML>
...
<HTML><BODY><P>Hi there! I'm being served from ip-172-31-33-149</P><P>AMI built from commit0ecbca35f91edf4d3e03476bfc84dc620efb1fa2</P><P>Travis build number28</P></BODY></HTML>
<HTML><BODY><P>Hi there! I'm being served from ip-172-31-9-73</P><P>AMI built from commit0ecbca35f91edf4d3e03476bfc84dc620efb1fa2</P><P>Travis build number28</P></BODY></HTML>
<HTML><BODY><P>Hi there! I'm being served from ip-172-31-33-149</P><P>AMI built from commit0ecbca35f91edf4d3e03476bfc84dc620efb1fa2</P><P>Travis build number28</P></BODY></HTML>
<HTML><BODY><P>Hi there! I'm being served from ip-172-31-33-149</P><P>AMI built from commit0ecbca35f91edf4d3e03476bfc84dc620efb1fa2</P><P>Travis build number28</P></BODY></HTML>
<HTML><BODY><P>Hi there! I'm being served from ip-172-31-9-73</P><P>AMI built from commit0ecbca35f91edf4d3e03476bfc84dc620efb1fa2</P><P>Travis build number28</P></BODY></HTML>
<HTML><BODY><P>Hi there! I'm being served from ip-172-31-9-73</P><P>AMI built from commit0ecbca35f91edf4d3e03476bfc84dc620efb1fa2</P><P>Travis build number28</P></BODY></HTML>
```
## Next steps

The solution is not perfect. Here are some additional opportunities to improve
the solution given time and effort.

### Pipeline speed and feedback cycle
Although the AMI based update of the images is robust, the overall time to build the images 
and deploy them is much longer than it should be. In a microservices environment, running each
microservice on a separate set of EC2s is likely to be expensive and not deliver against
expectations of speed and agility. In such a case, encapsulating the services in docker
images and scheduling them using e.g. ECS or EKS would likely be a more workable 
(but more complex) solution to the problem of keeping the pipeline responsive.

Alternatively it would be possible to use AWS CodeDeploy as a mechanism for deploying
the Node.JS packages to the instances without the need for baking an entire runtime
environment and deploying it.

### Rollbacks
The pipeline is rudimentary and works on
a fix-forward principle. Ideally if the 
deployment failed for any reason the launch 
template could be reverted to a previous AMI version or the latest version of the launch template deleted leaving the good
version as current.

### Observability
The application logs to journald. Ideally these
logs would all be shipped to a central log aggregation facility
such as Cloudwatch, ELK or Splunk, where the logs could be interrogated without the 
need for SSM. Ideally SSM would be used only _in extremis_ to inspect
the state of the machines. There are a number of utilities available
that can ship journald logs to cloudwatch. 

### Security
The same security group is leveraged for the ALB and the EC2 instances. Ideally they would
have more tightly controlled ingress and egress rules specific to each type of traffic.

### Better use of variables, less hard coding
There are some values, such as port numbers, ALB Names that are hard-coded within the
different code modules. Ideally these should be defined centrally and transmitted to each
of the individual elements of the job using variables.