# DirectPlugin 使用文档

## 1. 判断是否注册

### 功能说明
判断指定用户名是否已经完成注册。

### 调用方式
```javascript
croods.customPlugin({
    action: 'DirectPlugin.isReged',
    params: {
        userName: '用户名' // 必填，要查询的用户名
    },
    success: function (res) {
        // 成功回调
        // res.data: true表示已注册，false表示未注册
    },
    fail: function (msg) {
        // 失败回调
    }
})
```

### 参数说明
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| userName | String | 是 | 要查询的用户名 |

### 返回结果
成功回调返回格式：
```javascript
{
    "data": true/false // true表示已注册，false表示未注册
}
```

## 2. 注册

### 功能说明
为指定用户名进行注册操作。

### 调用方式
```javascript
croods.customPlugin({
    action: 'DirectPlugin.regOperation',
    params: {
        userName: '用户名' // 必填，要注册的用户名
    },
    success: function (res) {
        // 成功回调
        // res.data: sdk返回注册结果信息
        // res.code: sdk返回状态码，0表示成功
    },
    fail: function (msg) {
        // 失败回调
    }
})
```

### 参数说明
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| userName | String | 是 | 要注册的用户名 |

### 返回结果
成功回调返回格式：
```javascript
{
    "data": "注册结果信息",
    "code": 状态码 // 0表示成功
}
```

## 3. 验证

### 功能说明
验证用户身份，需要提供用户名和签名数据。

### 调用方式
```javascript
croods.customPlugin({
    action: 'DirectPlugin.authOperation',
    params: {
        userName: '用户名', // 必填，要验证的用户名
        signData: '签名数据' // 必填，验证所需的签名数据
    },
    success: function (res) {
        // 成功回调
        // res.data: 验证结果信息
        // res.code: 状态码，0表示成功
    },
    fail: function (msg) {
        // 失败回调
    }
})
```

### 参数说明
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| userName | String | 是 | 要验证的用户名 |
| signData | String | 是 | 验证所需的签名数据 |

### 返回结果
成功回调返回格式：
```javascript
{
    "data": "验证结果信息",
    "code": 状态码 // 表示成功
}
```

## 4. 活体检测

### 功能说明
启动活体检测功能，进行生物特征识别。

### 调用方式
```javascript
croods.customPlugin({
    action: 'DirectPlugin.startFos',
    params: {
        // 无需参数
    },
    success: function (res) {
        // 成功回调
        // res.code: 状态码
        // res.message: 检测结果消息
        // res.imageKey: 图像标识
        // res.image: 图像数据
    },
    fail: function (msg) {
        // 失败回调
    }
})
```

### 参数说明
无需参数

### 返回结果
成功回调返回格式：
```javascript
{
    "code": 状态码,
    "message": "检测结果消息",
    "imageKey": "图像标识",
    "image": "图像数据"
}
```

## 5. 缓存身份标识

### 功能说明
缓存用户身份标识信息到本地。

### 调用方式
```javascript
croods.customPlugin({
    action: 'DirectPlugin.setIdentity',
    params: {
        idKey: '标识键名', // 必填，身份标识的键名
        idValue: '标识值'  // 必填，身份标识的值
    },
    success: function (res) {
        // 成功回调
        // res.code: 状态码，0表示成功
    },
    fail: function (msg) {
        // 失败回调
    }
})
```

### 参数说明
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| idKey | String | 是 | 身份标识的键名 |
| idValue | String | 是 | 身份标识的值 |

### 返回结果
成功回调返回格式：
```javascript
{
    "code": 状态码 // 0表示成功
}
```
