クーポン情報取得API
====

クーポン情報取得APIを構築するためのSAM+Cloudformationベースのコードです。

## Description

基本的には以下の機能で構築
- Amazon API Gateway
- AWS Lambda
- AWS Lambda Layer
- Amazon DynamoDB
- Amazon S3
- AWS CloudFormation
- AWS Serverless Application Model

概要図
![クーポン配布API_構成 001](https://user-images.githubusercontent.com/8150485/65718106-d48e4a80-e0dd-11e9-83d4-d99c99fae9a3.png)

![クーポン配布API_構成 002](https://user-images.githubusercontent.com/8150485/65718147-e839b100-e0dd-11e9-9e5d-7fec633d67f8.png)

## API一覧

|No|API名|機能概要|
|--|----|----|
|1|ID指定取得|クーポンIDを指定してデータを返却する|
|2|タイトル検索|キーワードを入力して合致するタイトルのクーポン情報を返却する|
|3|ページング|最新の情報から5件返却する|
|4|次ページング|No.3で取得したlastEvaluatedKeyをベースに次の5件のクーポン情報を返却する|

## API詳細
### ID指定取得

処理概要：
パスパラメータでクーポンIDを指定することで、クーポンIDに紐づく画像URLやQRコードの画像URLを取得する。

|入力|パス|説明|
|--|-|-|
|アクセスURI|/resource/{resourceId}|{}部分にパスパラメータを設定|

|出力(JSON)|値の説明|
|--|-|
|statusCode|処理結果ステータス|
|headers||
|　Content-Type|application/json; charset=utf-8|
|body||
|　id|クーポンID|
|　updated_at|クーポン情報の登録日時|
|　coupon_type|ソート検索用|
|　title|クーポンタイトル|
|　descriptive_text|クーポン詳細|
|　coupon_url|クーポン画像のURL|
|　coupon_img_url|クーポンQRコード画像のURL|
|isBase64Encoded|False|

### タイトル検索
パスパラメータでキーワード指定することで、キーワードに合致するタイトルに紐づく画像URLやQRコードの画像URLを取得する。

|入力|パス|説明|
|--|-|-|
|アクセスURI|/search/{titlePart}|{}部分にパスパラメータを設定|

|出力(JSON)|値の説明|
|--|-|
|statusCode|処理結果ステータス|
|headers||
|　Content-Type|application/json; charset=utf-8|
|body|配列|
|　id|クーポンID|
|　updated_at|クーポン情報の登録日時|
|　coupon_type|ソート検索用|
|　title|クーポンタイトル|
|　descriptive_text|クーポン詳細|
|　coupon_url|クーポン画像のURL|
|　coupon_img_url|クーポンQRコード画像のURL|
|isBase64Encoded|False|

### ページング

|入力|パス|説明|
|--|-|-|
|アクセスURI| /resource-list|更新が新しい順から5件分クーポン情報を取得|

|出力(JSON)|値の説明|
|--|-|
|statusCode|処理結果ステータス|
|headers||
|　Content-Type|application/json; charset=utf-8|
|body||
|　Items|配列|
|　　id|クーポンID|
|　　updated_at|クーポン情報の登録日時|
|　　coupon_type|ソート検索用|
|　　title|クーポンタイトル|
|　　descriptive_text|クーポン詳細|
|　　coupon_url|クーポン画像のURL|
|　　coupon_img_url|クーポンQRコード画像のURL|
|LastEvaluatedKey|リクエスト時に取得できた最後のデータのKEY情報(JSON)。全件取得できた場合はNULL|
|以下省略||

### 次ページング

|入力|パス|説明|
|--|-|-|
|アクセスURI|/resource-list/{lastEvaluatedKey}|{}部分にNo.3で取得したキー情報を設定|

|出力(JSON)|値の説明|
|--|-|
|statusCode|処理結果ステータス|
|headers||
|　Content-Type|application/json; charset=utf-8|
|body||
|　Items|配列|
|　　id|クーポンID|
|　　updated_at|クーポン情報の登録日時|
|　　coupon_type|ソート検索用|
|　　title|クーポンタイトル|
|　　descriptive_text|クーポン詳細|
|　　coupon_url|クーポン画像のURL|
|　　coupon_img_url|クーポンQRコード画像のURL|
|LastEvaluatedKey|リクエスト時に取得できた最後のデータのKEY情報(JSON)。全件取得できた場合はNULL|
|以下省略||

## Author

[tomoki](https://github.com/tomoki10/)
