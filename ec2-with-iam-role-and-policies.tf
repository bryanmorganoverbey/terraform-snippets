

# Here’s how you can use an aws_iam_policy_document to
# define an assume role policy that allows the EC2 service to assume an IAM role:
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

variable "name" {
  description = "name forthe instance iam role "
  type        = string
  default     = "example_name"
}

# Now, you can use the aws_iam_role resource to create an IAM role and pass it the
# JSON from your aws_iam_policy_document to use as the assume role policy:
resource "aws_iam_role" "instance" {
  name_prefix        = var.name
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

# You now have an IAM role, but by default, IAM roles don’t give you any permissions.
# So, the next step is to attach one or more IAM policies to the IAM role that specify
# what you can actually do with the role once you’ve assumed it. Let’s imagine that you’re using
# Jenkins to run Terraform code that deploys EC2 Instances. You can use the aws_iam_policy_document
# data source to define an IAM Policy that gives admin permissions over EC2 Instances as follows:
data "aws_iam_policy_document" "ec2_admin_permissions" {
  statement {
    effect    = "Allow"
    actions   = ["ec2:*"]
    resources = ["*"]
  }
}

# And you can attach this policy to your IAM role using the aws_iam_role_policy resource:
resource "aws_iam_role_policy" "example" {
  role   = aws_iam_role.instance.id
  policy = data.aws_iam_policy_document.ec2_admin_permissions.json
}

# The final step is to allow your EC2 Instance to automatically assume that IAM role
#  by creating an instance profile:
resource "aws_iam_instance_profile" "instance" {
  role = aws_iam_role.instance.name
}

# And then tell your EC2 Instance to use that instance profile via the iam_instance_profile parameter:
resource "aws_instance" "example" {
  ami           = "ami-0fb653ca2d3203ac1"
  instance_type = "t2.micro"
  # Attach the instance profile
  iam_instance_profile = aws_iam_instance_profile.instance.name
}
