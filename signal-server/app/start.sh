#!/bin/sh

recoverAndFix() {
  git checkout -- "$1"
  for arg in "$@"; do
    if [ "$arg" = "$1" ]; then
      continue
    fi
    if ! sed -i "$arg" "$1"; then
      echo "sed -i $arg $1 failed"
      exit 1
    fi
  done
}
replace() {
  cp /myapp/src/"$1" "$1"
}
mkdir -p /git/src
cd /git/src || exit
if [ ! -f ./signal-server/LICENSE ]; then
  git clone --branch v7.71.0 https://github.com/signalapp/Signal-Server.git ./signal-server
fi
cd ./signal-server || exit
# fix local signal
{
  echo "start fix local signal"
  # 支持本地appConfig服务
  recoverAndFix ./service/src/main/java/org/whispersystems/textsecuregcm/configuration/AppConfigConfiguration.java 's#String configuration;#String configuration;\
  @JsonProperty\
  private String endpoint;\
  public String getEndpoint() {\
    return endpoint;\
  }#'
  # 支持本地appConfig服务
  recoverAndFix ./service/src/main/java/org/whispersystems/textsecuregcm/storage/DynamicConfigurationManager.java '/this(AppConfigDataClient/,+6d' 's#^public#\
import java.net.URI;\
import io.netty.util.internal.StringUtil;\
import software.amazon.awssdk.regions.Region;\
import software.amazon.awssdk.services.appconfigdata.AppConfigDataClientBuilder;\
import software.amazon.awssdk.auth.credentials.StaticCredentialsProvider;\
import software.amazon.awssdk.auth.credentials.AwsBasicCredentials;\
\
public#' 's#^      Class<T> configurationClass) {#      Class<T> configurationClass, String endpoint) {\
    final AppConfigDataClientBuilder builder = AppConfigDataClient\
        .builder()\
        .overrideConfiguration(ClientOverrideConfiguration.builder()\
            .apiCallTimeout(Duration.ofSeconds(10))\
            .apiCallAttemptTimeout(Duration.ofSeconds(10)).build());\
    if (!StringUtil.isNullOrEmpty(endpoint)) {\
      builder.endpointOverride(URI.create(endpoint)).region(Region.of("local"))\
          .credentialsProvider(StaticCredentialsProvider.create(\
              AwsBasicCredentials.create("accessKey", "secretKey")));\
    }\
    this.appConfigClient = builder.build();\
    this.application = application;\
    this.environment = environment;\
    this.configurationName = configurationName;\
    this.configurationClass = configurationClass;#'

  # 支持本地appConfig服务
  recoverAndFix ./service/src/main/java/org/whispersystems/textsecuregcm/workers/AssignUsernameCommand.java 's#DynamicConfiguration.class);#DynamicConfiguration.class, configuration.getAppConfig().getEndpoint());#'
  # 支持本地appConfig服务
  recoverAndFix ./service/src/main/java/org/whispersystems/textsecuregcm/workers/DeleteUserCommand.java 's#DynamicConfiguration.class);#DynamicConfiguration.class, configuration.getAppConfig().getEndpoint());#'
  # 支持本地appConfig服务
  recoverAndFix ./service/src/main/java/org/whispersystems/textsecuregcm/workers/SetUserDiscoverabilityCommand.java 's#DynamicConfiguration.class);#DynamicConfiguration.class, configuration.getAppConfig().getEndpoint());#'

  # 支持本地appConfig服务 使用本地dynamoDB 不使用currencyManager 不使用dataDog
  recoverAndFix ./service/src/main/java/org/whispersystems/textsecuregcm/WhisperServerService.java 's#DynamicConfiguration.class);#DynamicConfiguration.class, config.getAppConfig().getEndpoint());\
#' '/withRegion/,+6d' 's#AmazonDynamoDBClientBuilder.standard()#DynamoDbFromConfig.amazonDynamoDBClient(config.getDynamoDbClientConfiguration());#' \
    '/HttpClient                currencyClient/,+3d' '/environment.lifecycle().manage(currencyManager);/d' '/new PaymentsController(currencyManager, paymentsCredentialsGenerator),/d' \
    '/final DatadogMeterRegistry datadogMeterRegistry/,+20d'

  # 支持s3链接本地minio
  recoverAndFix ./service/src/main/java/org/whispersystems/textsecuregcm/configuration/CdnConfiguration.java 's#String region;#String region;\
  @JsonProperty\
  private String endpoint;\
  public String getEndpoint() {\
    return endpoint;\
  }#'

  # 支持gcp链接本地
  recoverAndFix ./service/src/main/java/org/whispersystems/textsecuregcm/configuration/GcpAttachmentsConfiguration.java 's#String domain;#String domain;\
  @JsonProperty\
  private String scheme;\
  public String getScheme() {\
    return scheme;\
  }#'

  # 请求sms验证码直接返回ok 请求人机验证直接返回ok
  recoverAndFix ./service/src/main/java/org/whispersystems/textsecuregcm/controllers/AccountController.java 's#RateLimitExceededException, ImpossiblePhoneNumberException, NonNormalizedPhoneNumberException {#RateLimitExceededException, ImpossiblePhoneNumberException, NonNormalizedPhoneNumberException {\
    if (true) {\
      return Response.ok().build();\
    }#' 's#final String countryCode#if (true) {\
      return new CaptchaRequirement(false, false);\
    }\
    final String countryCode#'

  # storageClient不使用SSL
  recoverAndFix ./service/src/main/java/org/whispersystems/textsecuregcm/securestorage/SecureStorageClient.java '/withSecurityProtocol/,+1d'

  # backupClient不使用SSL
  recoverAndFix ./service/src/main/java/org/whispersystems/textsecuregcm/securebackup/SecureBackupClient.java '/withSecurityProtocol/,+1d'

  # 账户协同服务不使用SSL
  recoverAndFix ./service/src/main/java/org/whispersystems/textsecuregcm/storage/DirectoryReconciliationClient.java '/KeyStore trustStor/,+5d' '/sslContext(sslContext)/d'

  # 请求sms验证码直接返回ok(没有申请证书)
  recoverAndFix ./service/src/main/java/org/whispersystems/textsecuregcm/recaptcha/RecaptchaClient.java '/try/,+10d' 's#dynamicConfigurationManager) {#dynamicConfigurationManager) {\
    this.projectPath = Objects.requireNonNull(projectPath);\
    this.client = null;\
    this.dynamicConfigurationManager = dynamicConfigurationManager;#'

  # 不使用apn
  recoverAndFix ./service/src/main/java/org/whispersystems/textsecuregcm/push/RetryingApnsClient.java '/setMetricsListener/,+3d' 's#this.apnsClient = new.*#this.apnsClient = null;#'

  # 使用本地dynamoDB
  recoverAndFix ./service/src/main/java/org/whispersystems/textsecuregcm/util/DynamoDbFromConfig.java 's#^public#\
import com.amazonaws.ClientConfiguration;\
import com.amazonaws.auth.AWSStaticCredentialsProvider;\
import com.amazonaws.auth.BasicAWSCredentials;\
import com.amazonaws.auth.InstanceProfileCredentialsProvider;\
import com.amazonaws.client.builder.AwsClientBuilder;\
import com.amazonaws.services.dynamodbv2.AmazonDynamoDB;\
import com.amazonaws.services.dynamodbv2.AmazonDynamoDBClientBuilder;\
import software.amazon.awssdk.auth.credentials.AwsBasicCredentials;\
import software.amazon.awssdk.auth.credentials.StaticCredentialsProvider;\
import java.net.URI;\
\
public#' 's#return DynamoDbAsyncClient#    if (config.getRegion().indexOf("http") == 0) {\
      return DynamoDbAsyncClient.builder()\
          .endpointOverride(URI.create(config.getRegion()))\
          .region(Region.of("local"))\
          .credentialsProvider(StaticCredentialsProvider.create(\
              AwsBasicCredentials.create("accessKey", "secretKey")))\
          .build();\
    }\
    return DynamoDbAsyncClient#' 's#return DynamoDbClient#    if (config.getRegion().indexOf("http") == 0) {\
      return DynamoDbClient.builder()\
          .endpointOverride(URI.create(config.getRegion()))\
          .region(Region.of("local"))\
          .credentialsProvider(StaticCredentialsProvider.create(\
              AwsBasicCredentials.create("accessKey", "secretKey")))\
          .build();\
    }\
    return DynamoDbClient#' 's#^}#\
  public static AmazonDynamoDB amazonDynamoDBClient(DynamoDbClientConfiguration config) {\
    AmazonDynamoDBClientBuilder dynamoDBClientBuilder = AmazonDynamoDBClientBuilder.standard()\
        .withClientConfiguration(\
            new ClientConfiguration()\
                .withClientExecutionTimeout(((int) config.getClientExecutionTimeout().toMillis()))\
                .withRequestTimeout((int) config.getClientRequestTimeout().toMillis())\
        );\
    if (config.getRegion().startsWith("http")) {\
      dynamoDBClientBuilder = dynamoDBClientBuilder.withEndpointConfiguration(\
              new AwsClientBuilder.EndpointConfiguration(config.getRegion(), "local"))\
          .withCredentials(new AWSStaticCredentialsProvider(new BasicAWSCredentials("accessKey", "secretKey")));\
    } else {\
      dynamoDBClientBuilder = dynamoDBClientBuilder.withRegion(config.getRegion())\
          .withCredentials(InstanceProfileCredentialsProvider.getInstance());\
    }\
    return dynamoDBClientBuilder.build();\
  }\
}#'
  # 防止报错
  recoverAndFix ./service/src/main/java/org/whispersystems/textsecuregcm/storage/NonNormalizedAccountCrawlerListener.java '/final int normalizedNumbers = metricsCluster.withCluster(connection/,+7d'\
  's#fromUuid) {#fromUuid) {\
    final int normalizedNumbers = metricsCluster.withCluster(connection -> {\
      Object v = connection.sync().get(NORMALIZED_NUMBER_COUNT_KEY);\
      if (v == null) {\
        return 0;\
      }\
      return Integer.parseInt(Optional.of(v.toString()).orElse("0"));\
    });\
    final int nonNormalizedNumbers = metricsCluster.withCluster(connection -> {\
      Object v = connection.sync().get(NON_NORMALIZED_NUMBER_COUNT_KEY);\
      if (v == null) {\
        return 0;\
      }\
      return Integer.parseInt(Optional.of(v.toString()).orElse("0"));\
    });\
    final int conflictingNumbers = metricsCluster.withCluster(connection -> {\
      Object v = connection.sync().get(CONFLICTING_NUMBER_COUNT_KEY);\
      if (v == null) {\
        return 0;\
      }\
      return Integer.parseInt(Optional.of(v.toString()).orElse("0"));\
    });\
  #'
  echo "finish fix local signal"
}

if [ ! -f ./service/target/TextSecureServer-7.71.0-dirty.jar ]; then
  echo "start build local signal"
  mvn package -DskipTests -Pexclude-abusive-message-filter
  echo "finish build local signal"
fi

if [ ! -f ./service/target/TextSecureServer-7.71.0-dirty.jar ]; then
  echo "build local signal fail"
  #1000 years
  sleep 31536000000
fi

if [ ! -f /myapp/zkparams.txt ]; then
  echo "start gen zkparams"
  java -jar /git/src/signal-server/service/target/TextSecureServer-7.71.0-dirty.jar zkparams >/myapp/zkparams.txt
  echo "finish gen zkparams"
  #替换配置文件
  echo "start modify sample's zkparams"
  publicKey=$(grep "Public" /myapp/zkparams.txt | awk '{print $2}')
  privateKey=$(grep "Private" /myapp/zkparams.txt | awk '{print $2}')
  sed -i "s#^  serverPublic:.*#  serverPublic: $publicKey#" /myapp/sample.yml
  sed -i "s#^  serverSecret:.*#  serverSecret: $privateKey#" /myapp/sample.yml
  echo "finish modify sample's zkparams"
fi

if [ ! -f /myapp/gcp_key.txt ]; then
  echo "start gen gcp_key"
  cd /myapp/src/rsa || exit
  javac Main.java && java Main >/myapp/gcp_key.txt
  cd - || exit
  echo "finish gen gcp_key"
  echo "start modify sample's gcp_key"
  cd /myapp/src/sedx || exit
  javac Main.java
  #提取私钥
  java Main /myapp/gcp_key.txt Public:_ -----END_PUBLIC_KEY----- | tee /myapp/gcp_pri.txt
  sed -i '/^Public:/,+2d' /myapp/gcp_pri.txt
  java Main /myapp/sample.yml '__rsaSigningKey:_|' ____-----END_PRIVATE_KEY----- /myapp/gcp_pri.txt ____ | tee /myapp/temp.yml
  cp /myapp/temp.yml /myapp/sample.yml
  rm /myapp/temp.yml
  rm /myapp/gcp_pri.txt
  cd - || exit
  echo "finish modify sample's gcp_key"
fi

if [ ! -f /myapp/unidentified_delivery_key.txt ]; then
  echo "start gen unidentified_delivery_key"
  java -jar /git/src/signal-server/service/target/TextSecureServer-7.71.0-dirty.jar certificate -ca >/myapp/unidentified_delivery_ca.txt
  privateKey=$(grep "Private key:" /myapp/unidentified_delivery_ca.txt | awk '{print $3}')
  java -jar /git/src/signal-server/service/target/TextSecureServer-7.71.0-dirty.jar certificate -k "$privateKey" -i 20230606 >/myapp/unidentified_delivery_key.txt
  echo "finish gen unidentified_delivery_key"
  privateKey=$(grep "Private key:" /myapp/unidentified_delivery_key.txt | awk '{print $3}')
  certificate=$(grep "Certificate:" /myapp/unidentified_delivery_key.txt | awk '{print $2}')

  echo "start modify sample's unidentified_delivery_key"
  sed -i "s#^  certificate:.*#  certificate: $certificate#" /myapp/sample.yml
  sed -i "s#^  privateKey:.*#  privateKey: $privateKey#" /myapp/sample.yml
  sed -i "s#^  expiresDays:.*#  expiresDays: 365#" /myapp/sample.yml
  echo "finish modify sample's unidentified_delivery_key"
fi

java -server -Djava.awt.headless=true -Xmx8192m -Xss512k -XX:+HeapDumpOnOutOfMemoryError -Dfile.encoding=utf-8 -jar /git/src/signal-server/service/target/TextSecureServer-7.71.0-dirty.jar server /myapp/sample.yml
