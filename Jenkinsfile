@Library('defra-docker-jenkins@initial-setup') _

import uk.gov.defra.ImageMap

ImageMap[] imageMaps = [
  [version: '3.1', tag: '3.1-alpine3.12', latest: true]
]

buildParentImage imageName: 'dotnetcore',
  imageMaps: imageMaps,
  version: '1.2.0'
