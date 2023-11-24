locals {
  eks_cluster_policy    = ["arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"]
  eks_node_group_policy = ["arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess", "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore", "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly", "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy", "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy", "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy", "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"]
}
/////
resource "aws_eks_node_group" "ondemend" {

  cluster_name = aws_eks_cluster.eks_cluster.name

  node_group_name = "test_app_node_group"

  subnet_ids = aws_subnet.k8s_subnet[*].id

  instance_types = ["t3.large"]

  release_version = nonsensitive(data.aws_ssm_parameter.eks_ami_release_version.value)

  scaling_config {
    desired_size = 2
    max_size     = 4
    min_size     = 2
  }

  node_role_arn = aws_iam_role.eks_node_group_role.arn

}

resource "aws_eks_node_group" "spot" {

  cluster_name = aws_eks_cluster.eks_cluster.name

  node_group_name = "test_app_spot_node_group"

  subnet_ids = aws_subnet.k8s_subnet[*].id

  instance_types = ["m5.large"]

  release_version = nonsensitive(data.aws_ssm_parameter.eks_ami_release_version.value)
  capacity_type = "SPOT"
  scaling_config {
    desired_size = 1
    max_size     = 6
    min_size     = 1
  }

  node_role_arn = aws_iam_role.eks_node_group_role.arn

}

# resource "aws_eks_node_group" "eks_node_gpu_group" {


#   cluster_name = aws_eks_cluster.eks_cluster.name

#   node_group_name = "test_app_gpu_node_group"

#   subnet_ids = aws_subnet.k8s_subnet[*].id

#   instance_types = ["g4dn.xlarge"]

#   ami_type        = "AL2_x86_64_GPU"
#   release_version = nonsensitive(data.aws_ssm_parameter.eks_gpu_ami_release_version.value)
#   scaling_config {
#     desired_size = 1
#     max_size     = 2
#     min_size     = 1
#   }
#   disk_size = 50

#   node_role_arn = aws_iam_role.eks_node_group_role.arn

# }

resource "aws_eks_cluster" "eks_cluster" {
  name     = "test_app_eks_cluster"
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = "1.28"

  vpc_config {
    subnet_ids              = aws_subnet.k8s_subnet[*].id
    security_group_ids      = [aws_security_group.eks_node_group_sg.id]
 //   endpoint_private_access = true
    endpoint_public_access  = true
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy
  ]


}

resource "aws_iam_role" "eks_cluster_role" {
  name = "test_app_eks_cluster_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })
}


resource "aws_iam_role" "eks_node_group_role" {
  name = "test_app_eks_node_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}





resource "aws_security_group" "eks_node_group_sg" {
  name        = "node-group-sg"
  description = "For Nodegroup"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [aws_vpc.vpc.cidr_block]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  // tags = local.resource_tags
}
# resource "aws_autoscaling_policy" "upscail" {
#   autoscaling_group_name = aws_eks_node_group.eks_node_gpu_group .resources[0].autoscaling_groups[0].name
#   name                   = "upscail"
#   cooldown              = 180
#   adjustment_type = "ChangeInCapacity"
#   scaling_adjustment   =    1
# }
# resource "aws_autoscaling_policy" "downscail" {
#   autoscaling_group_name = aws_eks_node_group.eks_node_gpu_group .resources[0].autoscaling_groups[0].name
#   name                   = "downscail"
#   cooldown              = 180
#   adjustment_type = "ChangeInCapacity"
#   scaling_adjustment   =    -1
# }




# resource "aws_cloudwatch_metric_alarm" "mqalarm_up" {
#   alarm_name                = "mqalarmup"
#   comparison_operator       = "GreaterThanThreshold"
#   evaluation_periods        = 1
#   metric_name               = "MessageCount"
#   namespace                 = "AWS/AmazonMQ"
#   period                    = 60
#   threshold                 = 10
#   statistic                 = "Average"
#   alarm_description         = "for mq upscail"
#   dimensions = {
#     Broker = var.broker_name
#     VirtualHost = "/"
#     Queue = "mix"    
#   }
#   alarm_actions = [aws_autoscaling_policy.upscail.arn]
# }


# resource "aws_cloudwatch_metric_alarm" "mqalarm_down" {
#   alarm_name                = "mqalarmdown"
#   comparison_operator       = "LessThanThreshold"
#   evaluation_periods        = 1
#   metric_name               = "MessageCount"
#   namespace                 = "AWS/AmazonMQ"
#   period                    = 60
#   threshold                 = 5
#   statistic                 = "Average"
#   alarm_description         = "for mq downscail"
#   dimensions = {
#     Broker = var.broker_name
#     VirtualHost = "/"
#     Queue = "mix"    
#   }
#   alarm_actions = [aws_autoscaling_policy.downscail.arn]
# }


# #    # "metrics": [
# #   #     [ "AWS/AmazonMQ", "QueueCount", "Broker", "dev-broker", { "stat": "Maximum" } ]
# #   # ],





///////////////////
/// policy ////////
///////////////////


resource "aws_iam_openid_connect_provider" "iamoidc" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.external.thumbprint.result.thumbprint]
  url             = aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer
}


resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  for_each   = toset(local.eks_cluster_policy)
  policy_arn = each.key
  role       = aws_iam_role.eks_cluster_role.name
}

resource "aws_iam_role_policy_attachment" "eks_node_group_policy" {
  for_each   = toset(local.eks_node_group_policy)
  policy_arn = each.key
  role       = aws_iam_role.eks_node_group_role.name
}


resource "aws_iam_role_policy" "eks_for_route53_policy" {
  name = "test_app_EKSRoute53Policy"
  role = aws_iam_role.eks_node_group_role.id
  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Action" : [
            "route53:ChangeResourceRecordSets"
          ],
          "Resource" : [
            "arn:aws:route53:::hostedzone/*"
          ]
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "route53:ListHostedZones",
            "route53:ListResourceRecordSets"
          ],
          "Resource" : [
            "*"
          ]
        }
      ]
    }
  )
}


resource "aws_iam_role_policy" "alc_controller_policy" {
  name = "test_app_EKSALBCPolicy"
  role = aws_iam_role.eks_node_group_role.id
  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Action" : [
            "iam:CreateServiceLinkedRole"
          ],
          "Resource" : "*",
          "Condition" : {
            "StringEquals" : {
              "iam:AWSServiceName" : "elasticloadbalancing.amazonaws.com"
            }
          }
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "ec2:DescribeAccountAttributes",
            "ec2:DescribeAddresses",
            "ec2:DescribeAvailabilityZones",
            "ec2:DescribeInternetGateways",
            "ec2:DescribeVpcs",
            "ec2:DescribeVpcPeeringConnections",
            "ec2:DescribeSubnets",
            "ec2:DescribeSecurityGroups",
            "ec2:DescribeInstances",
            "ec2:DescribeNetworkInterfaces",
            "ec2:DescribeTags",
            "ec2:GetCoipPoolUsage",
            "ec2:DescribeCoipPools",
            "elasticloadbalancing:DescribeLoadBalancers",
            "elasticloadbalancing:DescribeLoadBalancerAttributes",
            "elasticloadbalancing:DescribeListeners",
            "elasticloadbalancing:DescribeListenerCertificates",
            "elasticloadbalancing:DescribeSSLPolicies",
            "elasticloadbalancing:DescribeRules",
            "elasticloadbalancing:DescribeTargetGroups",
            "elasticloadbalancing:DescribeTargetGroupAttributes",
            "elasticloadbalancing:DescribeTargetHealth",
            "elasticloadbalancing:DescribeTags"
          ],
          "Resource" : "*"
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "cognito-idp:DescribeUserPoolClient",
            "acm:ListCertificates",
            "acm:DescribeCertificate",
            "iam:ListServerCertificates",
            "iam:GetServerCertificate",
            "waf-regional:GetWebACL",
            "waf-regional:GetWebACLForResource",
            "waf-regional:AssociateWebACL",
            "waf-regional:DisassociateWebACL",
            "wafv2:GetWebACL",
            "wafv2:GetWebACLForResource",
            "wafv2:AssociateWebACL",
            "wafv2:DisassociateWebACL",
            "shield:GetSubscriptionState",
            "shield:DescribeProtection",
            "shield:CreateProtection",
            "shield:DeleteProtection"
          ],
          "Resource" : "*"
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "ec2:AuthorizeSecurityGroupIngress",
            "ec2:RevokeSecurityGroupIngress"
          ],
          "Resource" : "*"
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "ec2:CreateSecurityGroup"
          ],
          "Resource" : "*"
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "ec2:CreateTags"
          ],
          "Resource" : "arn:aws:ec2:*:*:security-group/*",
          "Condition" : {
            "StringEquals" : {
              "ec2:CreateAction" : "CreateSecurityGroup"
            },
            "Null" : {
              "aws:RequestTag/elbv2.k8s.aws/cluster" : "false"
            }
          }
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "ec2:CreateTags",
            "ec2:DeleteTags"
          ],
          "Resource" : "arn:aws:ec2:*:*:security-group/*",
          "Condition" : {
            "Null" : {
              "aws:RequestTag/elbv2.k8s.aws/cluster" : "true",
              "aws:ResourceTag/elbv2.k8s.aws/cluster" : "false"
            }
          }
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "ec2:AuthorizeSecurityGroupIngress",
            "ec2:RevokeSecurityGroupIngress",
            "ec2:DeleteSecurityGroup"
          ],
          "Resource" : "*",
          "Condition" : {
            "Null" : {
              "aws:ResourceTag/elbv2.k8s.aws/cluster" : "false"
            }
          }
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "elasticloadbalancing:CreateLoadBalancer",
            "elasticloadbalancing:CreateTargetGroup"
          ],
          "Resource" : "*",
          "Condition" : {
            "Null" : {
              "aws:RequestTag/elbv2.k8s.aws/cluster" : "false"
            }
          }
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "elasticloadbalancing:CreateListener",
            "elasticloadbalancing:DeleteListener",
            "elasticloadbalancing:CreateRule",
            "elasticloadbalancing:DeleteRule"
          ],
          "Resource" : "*"
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "elasticloadbalancing:AddTags",
            "elasticloadbalancing:RemoveTags"
          ],
          "Resource" : [
            "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*",
            "arn:aws:elasticloadbalancing:*:*:loadbalancer/net/*/*",
            "arn:aws:elasticloadbalancing:*:*:loadbalancer/app/*/*"
          ],
          "Condition" : {
            "Null" : {
              "aws:RequestTag/elbv2.k8s.aws/cluster" : "true",
              "aws:ResourceTag/elbv2.k8s.aws/cluster" : "false"
            }
          }
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "elasticloadbalancing:AddTags",
            "elasticloadbalancing:RemoveTags"
          ],
          "Resource" : [
            "arn:aws:elasticloadbalancing:*:*:listener/net/*/*/*",
            "arn:aws:elasticloadbalancing:*:*:listener/app/*/*/*",
            "arn:aws:elasticloadbalancing:*:*:listener-rule/net/*/*/*",
            "arn:aws:elasticloadbalancing:*:*:listener-rule/app/*/*/*"
          ]
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "elasticloadbalancing:ModifyLoadBalancerAttributes",
            "elasticloadbalancing:SetIpAddressType",
            "elasticloadbalancing:SetSecurityGroups",
            "elasticloadbalancing:SetSubnets",
            "elasticloadbalancing:DeleteLoadBalancer",
            "elasticloadbalancing:ModifyTargetGroup",
            "elasticloadbalancing:ModifyTargetGroupAttributes",
            "elasticloadbalancing:DeleteTargetGroup"
          ],
          "Resource" : "*",
          "Condition" : {
            "Null" : {
              "aws:ResourceTag/elbv2.k8s.aws/cluster" : "false"
            }
          }
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "elasticloadbalancing:AddTags"
          ],
          "Resource" : [
            "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*",
            "arn:aws:elasticloadbalancing:*:*:loadbalancer/net/*/*",
            "arn:aws:elasticloadbalancing:*:*:loadbalancer/app/*/*"
          ],
          "Condition" : {
            "StringEquals" : {
              "elasticloadbalancing:CreateAction" : [
                "CreateTargetGroup",
                "CreateLoadBalancer"
              ]
            },
            "Null" : {
              "aws:RequestTag/elbv2.k8s.aws/cluster" : "false"
            }
          }
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "elasticloadbalancing:RegisterTargets",
            "elasticloadbalancing:DeregisterTargets"
          ],
          "Resource" : "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*"
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "elasticloadbalancing:SetWebAcl",
            "elasticloadbalancing:ModifyListener",
            "elasticloadbalancing:AddListenerCertificates",
            "elasticloadbalancing:RemoveListenerCertificates",
            "elasticloadbalancing:ModifyRule"
          ],
          "Resource" : "*"
        }
      ]
    }
  )
}

module "cluster_autoscaler_irsa_role" {

  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name                        = "cluster-autoscaler"
  attach_cluster_autoscaler_policy = true
  cluster_autoscaler_cluster_names = [aws_eks_cluster.eks_cluster.name]

  oidc_providers = {
    main = {
      provider_arn               = aws_iam_openid_connect_provider.iamoidc.arn
      namespace_service_accounts = ["kube-system:cluster-autoscaler"]
    }
  }
}



// data

data "aws_ssm_parameter" "eks_ami_release_version" {
  name = "/aws/service/eks/optimized-ami/${aws_eks_cluster.eks_cluster.version}/amazon-linux-2/recommended/release_version"
}
//gpu 버전 ami
data "aws_ssm_parameter" "eks_gpu_ami_release_version" {
  name = "/aws/service/eks/optimized-ami/${aws_eks_cluster.eks_cluster.version}/amazon-linux-2-gpu/recommended/release_version"
}


data "external" "thumbprint" {
  program = ["sh", "${path.module}/get_thumbprint.sh", data.aws_region.current.name]
}

data "aws_region" "current" {}