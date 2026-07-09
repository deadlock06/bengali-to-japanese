---
name: integration-aws
description: >-
  AWS integration skill. Auto-activates when working with AWS services —
  S3, Lambda, CloudFront, EC2, RDS, DynamoDB, SQS, SNS, IAM, API Gateway,
  Cognito, CloudWatch, or the AWS Marketplace. Also activates on: amazon web
  services, AWS, S3 bucket, Lambda function, CloudFront CDN, EC2 instance,
  IAM role, API Gateway, Cognito user pool, CloudWatch logs, terraform, CDK,
  CloudFormation, SENSEI content CDN, model hosting, audio hosting, pack
  delivery, content distribution, cost optimization, serverless AWS.
---

# AWS Integration Guide

## You have AWS Marketplace connected to Claude
The AWS integration lets Claude help configure, architect, and debug AWS
services — and access AWS Marketplace offerings directly.

## How Claude uses this integration
Claude can:
- Help architect AWS infrastructure for SENSEI backend services
- Write CloudFormation / CDK templates
- Debug Lambda functions and CloudWatch logs
- Find relevant AWS Marketplace products
- Estimate costs using AWS Pricing Calculator approach

## SENSEI — AWS role
AWS may serve as infrastructure for SENSEI's optional cloud services:

### Content CDN (most likely use)
```
S3 → CloudFront → SENSEI app (content pack downloads)

Structure:
  s3://sensei-content/
    packs/
      jft-a2-konbini-v1.zip  (hash-verified)
      pitch-basics-v1.zip
    models/
      llama-7b-q4.gguf       (large — hash-verified download)
      whisper-small.bin
      kokoro-82m.onnx

CloudFront: cache 24h, gzip, range-request support (for large model files)
```

### Lambda (content signing / webhook)
```javascript
// Lambda: sign content pack URLs (time-limited S3 presigned URLs)
// Trigger: API Gateway POST /content/request-pack
// Auth: Supabase JWT verification before signing
// Never: expose raw S3 bucket URLs to clients
```

### Cost targets (per 12_BUSINESS_GTM)
```
Content CDN:   < $0.10 / GB (S3 + CloudFront)
Lambda:        free tier covers most usage
Total cloud:   < $50/month at 10K MAU (offline-first keeps this low)
```

## AWS Marketplace — relevant services for SENSEI
- **AI/ML**: SageMaker endpoints (if on-device AI needs cloud fallback)
- **Translation**: Amazon Translate (Bengali ↔ Japanese ↔ English pipeline)
- **Polly**: TTS fallback (if Kokoro offline isn't sufficient)
- **Comprehend**: Bengali NLP (future — grammar analysis)

## IAM best practices
```json
// Least privilege: content reader role for app
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Action": ["s3:GetObject"],
    "Resource": "arn:aws:s3:::sensei-content/packs/*"
  }]
}
// Never: AdministratorAccess on app-facing roles
// Never: Access keys in app code — use IAM roles + presigned URLs
```

## Offline-first constraint
AWS is always **optional enhancement** — the app must work with zero AWS
access. Content packs cached locally. Model files downloaded once, stored locally.
