#!/bin/sh

recoverAndFix() {
  git checkout -- "$1"
  for arg in "$@"; do
    if [ "$arg" = "$1" ]; then
      continue
    fi
    sed -i "$arg" "$1"
  done
}

mkdir -p /git/src
cd /git/src || exit
if [ ! -f ./signal-server/LICENSE ]; then
  git clone --branch v7.71.0 https://github.com/signalapp/Signal-Server.git ./signal-server
fi
cd ./signal-server || exit

echo "start fix local signal"

#cdn 添加 endpoint
recoverAndFix ./service/src/main/java/org/whispersystems/textsecuregcm/configuration/CdnConfiguration.java 's#String region;#String region;\
  @JsonProperty\
  private String endpoint;\
  public String getEndpoint() {\
    return endpoint;\
  }#'

#gcp 添加 scheme
recoverAndFix ./service/src/main/java/org/whispersystems/textsecuregcm/configuration/GcpAttachmentsConfiguration.java 's#String domain;#String domain;\
  @JsonProperty\
  private String scheme;\
  public String getScheme() {\
    return scheme;\
  }#'

#请求sms验证码, 直接返回ok & 请求人机验证, 直接返回ok
recoverAndFix ./service/src/main/java/org/whispersystems/textsecuregcm/controllers/AccountController.java 's#RateLimitExceededException, ImpossiblePhoneNumberException, NonNormalizedPhoneNumberException {#RateLimitExceededException, ImpossiblePhoneNumberException, NonNormalizedPhoneNumberException {\
    if (true) {\
      return Response.ok().build();\
    }#' 's#final String countryCode#if (true) {\
      return new CaptchaRequirement(false, false);\
    }\
    final String countryCode#'

echo "finish fix local signal"

echo "start build local signal"
mvn clean package -DskipTests -Pexclude-abusive-message-filter
echo "finish build local signal"

java -server -Djava.awt.headless=true -Xmx8192m -Xss512k -XX:+HeapDumpOnOutOfMemoryError -Dfile.encoding=utf-8 -jar /git/src/signal-server/service/target/TextSecureServer-7.71.0-dirty.jar server /myapp/sample.yml

