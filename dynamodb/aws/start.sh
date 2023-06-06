#!/usr/bin/env bash
if [ ! -f /tmp/finish ]; then
  #accounts:
  #  tableName: Example_Accounts
  #  phoneNumberTableName: Example_Accounts_PhoneNumbers
  #  phoneNumberIdentifierTableName: Example_Accounts_PhoneNumberIdentifiers
  #  usernamesTableName: Example_Accounts_Usernames
  #  scanPageSize: 100
  tableName=$(grep "^  accounts" -A 1 /mysignal/sample.yml | grep tableName | awk '{print $2}')
  aws dynamodb create-table --table-name "$tableName" --attribute-definitions AttributeName=U,AttributeType=B --key-schema AttributeName=U,KeyType=HASH --provisioned-throughput ReadCapacityUnits=1,WriteCapacityUnits=1 --endpoint-url http://172.23.0.3:8000
  tableName=$(grep "phoneNumberTableName" /mysignal/sample.yml | awk '{print $2}')
  aws dynamodb create-table --table-name "$tableName" --attribute-definitions AttributeName=P,AttributeType=S --key-schema AttributeName=P,KeyType=HASH --provisioned-throughput ReadCapacityUnits=20,WriteCapacityUnits=20 --endpoint-url http://172.23.0.3:8000
  tableName=$(grep "phoneNumberIdentifierTableName" /mysignal/sample.yml | awk '{print $2}')
  aws dynamodb create-table --table-name "$tableName" --attribute-definitions AttributeName=PNI,AttributeType=B --key-schema AttributeName=PNI,KeyType=HASH --provisioned-throughput ReadCapacityUnits=20,WriteCapacityUnits=20 --endpoint-url http://172.23.0.3:8000
  tableName=$(grep "usernamesTableName" /mysignal/sample.yml | awk '{print $2}')
  aws dynamodb create-table --table-name "$tableName" --attribute-definitions AttributeName=N,AttributeType=S --key-schema AttributeName=N,KeyType=HASH --provisioned-throughput ReadCapacityUnits=20,WriteCapacityUnits=20 --endpoint-url http://172.23.0.3:8000

  #deletedAccounts:
  #  tableName: Example_DeletedAccounts
  #  needsReconciliationIndexName: NeedsReconciliation
  tableName=$(grep "^  deletedAccounts:" -A 1 /mysignal/sample.yml | grep tableName | awk '{print $2}')
  needsReconciliationIndexName=$(grep "needsReconciliationIndexName" /mysignal/sample.yml | awk '{print $2}')
  aws dynamodb create-table \
    --table-name "$tableName" \
    --attribute-definitions AttributeName=U,AttributeType=B AttributeName=P,AttributeType=S AttributeName=R,AttributeType=N \
    --key-schema AttributeName=P,KeyType=HASH \
    --provisioned-throughput ReadCapacityUnits=20,WriteCapacityUnits=20 \
    --global-secondary-indexes \
    "[
  {
    \"IndexName\":\"$needsReconciliationIndexName\",
    \"KeySchema\":[
      {\"AttributeName\":\"P\",\"KeyType\":\"HASH\"},
      {\"AttributeName\":\"R\",\"KeyType\":\"RANGE\"}
    ],
    \"Projection\":{
      \"ProjectionType\":\"INCLUDE\",
      \"NonKeyAttributes\":[\"U\"]
    },
    \"ProvisionedThroughput\":{
      \"ReadCapacityUnits\":10,
      \"WriteCapacityUnits\":10
    }
  },
  {
    \"IndexName\":\"u_to_p\",
    \"KeySchema\":[
      {\"AttributeName\":\"U\",\"KeyType\":\"HASH\"}
    ],
    \"Projection\":{
      \"ProjectionType\":\"KEYS_ONLY\"
    },
    \"ProvisionedThroughput\":{
      \"ReadCapacityUnits\":10,
      \"WriteCapacityUnits\":10
    }
  }
]" \
    --endpoint-url http://172.23.0.3:8000

  #deletedAccountsLock:
  #  tableName: Example_DeletedAccountsLock
  tableName=$(grep "^  deletedAccountsLock:" -A 1 /mysignal/sample.yml | grep tableName | awk '{print $2}')
  aws dynamodb create-table --table-name "$tableName" --attribute-definitions AttributeName=P,AttributeType=S --key-schema AttributeName=P,KeyType=HASH --provisioned-throughput ReadCapacityUnits=20,WriteCapacityUnits=20 --endpoint-url http://172.23.0.3:8000
  #issuedReceipts:
  #  tableName: Example_IssuedReceipts
  #  expiration: P30D # Duration of time until rows expire
  #  generator: abcdefg12345678= # random base64-encoded binary sequence
  tableName=$(grep "^  issuedReceipts:" -A 1 /mysignal/sample.yml | grep tableName | awk '{print $2}')
  aws dynamodb create-table --table-name "$tableName" --attribute-definitions AttributeName=A,AttributeType=S --key-schema AttributeName=A,KeyType=HASH --provisioned-throughput ReadCapacityUnits=20,WriteCapacityUnits=20 --endpoint-url http://172.23.0.3:8000
  #keys:
  #  tableName: Example_Keys
  tableName=$(grep "^  keys:" -A 1 /mysignal/sample.yml | grep tableName | awk '{print $2}')
  aws dynamodb create-table --table-name "$tableName" --attribute-definitions AttributeName=U,AttributeType=B AttributeName=DK,AttributeType=B --key-schema AttributeName=U,KeyType=HASH AttributeName=DK,KeyType=RANGE --provisioned-throughput ReadCapacityUnits=20,WriteCapacityUnits=20 --endpoint-url http://172.23.0.3:8000
  #messages:
  #  tableName: Example_Messages
  #  expiration: P30D # Duration of time until rows expire
  tableName=$(grep "^  messages:" -A 1 /mysignal/sample.yml | grep tableName | awk '{print $2}')
  aws dynamodb create-table --table-name "$tableName" \
    --attribute-definitions AttributeName=H,AttributeType=B AttributeName=S,AttributeType=B AttributeName=U,AttributeType=B \
    --key-schema AttributeName=H,KeyType=HASH AttributeName=S,KeyType=RANGE \
    --provisioned-throughput ReadCapacityUnits=20,WriteCapacityUnits=20 \
    --local-secondary-indexes \
    "[
  {
    \"IndexName\":\"Message_UUID_Index\",
    \"KeySchema\":[
      {\"AttributeName\":\"H\",\"KeyType\":\"HASH\"},
      {\"AttributeName\":\"U\",\"KeyType\":\"RANGE\"}
    ],
    \"Projection\":{
      \"ProjectionType\":\"KEYS_ONLY\"
    }
  }
]" \
    --endpoint-url http://172.23.0.3:8000

  #pendingAccounts:
  #  tableName: Example_PendingAccounts
  tableName=$(grep "^  pendingAccounts:" -A 1 /mysignal/sample.yml | grep tableName | awk '{print $2}')
  aws dynamodb create-table --table-name "$tableName" --attribute-definitions AttributeName=P,AttributeType=S --key-schema AttributeName=P,KeyType=HASH --provisioned-throughput ReadCapacityUnits=20,WriteCapacityUnits=20 --endpoint-url http://172.23.0.3:8000
  #pendingDevices:
  #  tableName: Example_PendingDevices
  tableName=$(grep "^  pendingDevices:" -A 1 /mysignal/sample.yml | grep tableName | awk '{print $2}')
  aws dynamodb create-table --table-name "$tableName" --attribute-definitions AttributeName=P,AttributeType=S --key-schema AttributeName=P,KeyType=HASH --provisioned-throughput ReadCapacityUnits=20,WriteCapacityUnits=20 --endpoint-url http://172.23.0.3:8000
  #phoneNumberIdentifiers:
  #  tableName: Example_PhoneNumberIdentifiers
  tableName=$(grep "^  phoneNumberIdentifiers:" -A 1 /mysignal/sample.yml | grep tableName | awk '{print $2}')
  aws dynamodb create-table --table-name "$tableName" \
    --attribute-definitions AttributeName=P,AttributeType=S AttributeName=PNI,AttributeType=B \
    --key-schema AttributeName=P,KeyType=HASH \
    --provisioned-throughput ReadCapacityUnits=20,WriteCapacityUnits=20 \
    --global-secondary-indexes \
    "[
  {
    \"IndexName\":\"pni_to_p\",
    \"KeySchema\":[
      {\"AttributeName\":\"PNI\",\"KeyType\":\"HASH\"}
    ],
    \"Projection\":{
      \"ProjectionType\":\"KEYS_ONLY\"
    },
    \"ProvisionedThroughput\":{
      \"ReadCapacityUnits\":10,
      \"WriteCapacityUnits\":10
    }
  }
]" \
    --endpoint-url http://172.23.0.3:8000
  #profiles:
  #  tableName: Example_Profiles
  tableName=$(grep "^  profiles:" -A 1 /mysignal/sample.yml | grep tableName | awk '{print $2}')
  aws dynamodb create-table --table-name "$tableName" --attribute-definitions AttributeName=U,AttributeType=B AttributeName=V,AttributeType=S --key-schema AttributeName=U,KeyType=HASH AttributeName=V,KeyType=RANGE --provisioned-throughput ReadCapacityUnits=20,WriteCapacityUnits=20 --endpoint-url http://172.23.0.3:8000
  #pushChallenge:
  #  tableName: Example_PushChallenge
  tableName=$(grep "^  pushChallenge:" -A 1 /mysignal/sample.yml | grep tableName | awk '{print $2}')
  aws dynamodb create-table --table-name "$tableName" --attribute-definitions AttributeName=U,AttributeType=B --key-schema AttributeName=U,KeyType=HASH --provisioned-throughput ReadCapacityUnits=20,WriteCapacityUnits=20 --endpoint-url http://172.23.0.3:8000
  #redeemedReceipts:
  #  tableName: Example_RedeemedReceipts
  #  expiration: P30D # Duration of time until rows expire
  tableName=$(grep "^  redeemedReceipts:" -A 1 /mysignal/sample.yml | grep tableName | awk '{print $2}')
  aws dynamodb create-table --table-name "$tableName" --attribute-definitions AttributeName=S,AttributeType=B --key-schema AttributeName=S,KeyType=HASH --provisioned-throughput ReadCapacityUnits=20,WriteCapacityUnits=20 --endpoint-url http://172.23.0.3:8000
  #remoteConfig:
  #  tableName: Example_RemoteConfig
  tableName=$(grep "^  remoteConfig:" -A 1 /mysignal/sample.yml | grep tableName | awk '{print $2}')
  aws dynamodb create-table --table-name "$tableName" --attribute-definitions AttributeName=N,AttributeType=S --key-schema AttributeName=N,KeyType=HASH --provisioned-throughput ReadCapacityUnits=20,WriteCapacityUnits=20 --endpoint-url http://172.23.0.3:8000
  #reportMessage:
  #  tableName: Example_ReportMessage
  tableName=$(grep "^  reportMessage:" -A 1 /mysignal/sample.yml | grep tableName | awk '{print $2}')
  aws dynamodb create-table --table-name "$tableName" --attribute-definitions AttributeName=H,AttributeType=B --key-schema AttributeName=H,KeyType=HASH --provisioned-throughput ReadCapacityUnits=20,WriteCapacityUnits=20 --endpoint-url http://172.23.0.3:8000
  #reservedUsernames:
  #  tableName: Example_ReservedUsernames
  tableName=$(grep "^  reservedUsernames:" -A 1 /mysignal/sample.yml | grep tableName | awk '{print $2}')
  aws dynamodb create-table --table-name "$tableName" --attribute-definitions AttributeName=P,AttributeType=S --key-schema AttributeName=P,KeyType=HASH --provisioned-throughput ReadCapacityUnits=20,WriteCapacityUnits=20 --endpoint-url http://172.23.0.3:8000
  #subscriptions:
  #  tableName: Example_Subscriptions
  tableName=$(grep "^  subscriptions:" -A 1 /mysignal/sample.yml | grep tableName | awk '{print $2}')
  aws dynamodb create-table --table-name "$tableName" \
    --attribute-definitions AttributeName=U,AttributeType=B AttributeName=C,AttributeType=S \
    --key-schema AttributeName=U,KeyType=HASH \
    --global-secondary-indexes \
    "[
  {
    \"IndexName\":\"c_to_u\",
    \"KeySchema\":[
      {\"AttributeName\":\"C\",\"KeyType\":\"HASH\"}
    ],
    \"Projection\":{
      \"ProjectionType\":\"KEYS_ONLY\"
    },
    \"ProvisionedThroughput\":{
      \"ReadCapacityUnits\":10,
      \"WriteCapacityUnits\":10
    }
  }
]" \
    --provisioned-throughput ReadCapacityUnits=20,WriteCapacityUnits=20 \
    --endpoint-url http://172.23.0.3:8000
  echo "finish" >/tmp/finish
fi

#1000 years
sleep 31536000000
