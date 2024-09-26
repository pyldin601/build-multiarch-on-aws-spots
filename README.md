# Build multiarch docker image on AWS spot instances

Example:

```
name: Build multiarch docker image

on: [workflow_dispatch]

jobs:
  build:
    name: Build
    uses: pldin601/build-multiarch-on-aws-spots/.github/workflows/build-multiarch-on-aws-spots.yml@v1.1.2
    with:
      DOCKER_IMAGE_TAG: v1.1.2
      WORKFLOW_CHECKOUT: master # Should be the same as the ref used in "uses" expression.
      AWS_REGION: eu-central-1
      AWS_EC2_INSTANCE_SIZE: large
    secrets:
      AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
      AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
      DOCKERHUB_USERNAME: ${{ secrets.DOCKERHUB_USERNAME }}
      DOCKERHUB_TOKEN: ${{ secrets.DOCKERHUB_TOKEN }}
```
