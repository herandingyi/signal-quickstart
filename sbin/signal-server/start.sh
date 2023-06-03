#!/bin/sh

mkdir -p /git/src && cd /git/src

if [ ! -f LICENSE ]; then
  git clone --branch v7.71.0 https://github.com/signalapp/Signal-Server.git .

  #cdn 添加 endpoint
  sed 's#String region;#String region;\
  @JsonProperty\
  private String endpoint;\
  public String getEndpoint() {\
    return endpoint;\
  }#' ./service/src/main/java/org/whispersystems/textsecuregcm/configuration/CdnConfiguration.java

  #gcp 添加 scheme
  sed 's#String domain;#String domain;\
  @NotEmpty\
  @JsonProperty\
  private String scheme;\
  public String getScheme() {\
    return scheme;\
  }#' ./service/src/main/java/org/whispersystems/textsecuregcm/configuration/GcpAttachmentsConfiguration.java

  #请求验证码, 直接返回ok
  sed 's#RateLimitExceededException, ImpossiblePhoneNumberException, NonNormalizedPhoneNumberException {#RateLimitExceededException, ImpossiblePhoneNumberException, NonNormalizedPhoneNumberException {\
  if (true) {\
    return Response.ok().build();\
  }#' ./service/src/main/java/org/whispersystems/textsecuregcm/controllers/AccountController.java


  mvn clean package -DskipTests -Pexclude-abusive-message-filter

fi
