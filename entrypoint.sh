#!/bin/bash

# 生成随机UUID（Netlify每次部署自动刷新）
UUID=$(cat /proc/sys/kernel/random/uuid)

# 路径配置（需与Netlify路由匹配）
VMESS_WSPATH='/vmess'
VLESS_WSPATH='/vless'
TROJAN_WSPATH='/trojan'
SS_WSPATH='/shadowsocks'

# Netlify适配版配置生成
generate_netlify_config() {
  cat > netlify.toml << EOF
[build]
  command = "chmod +x build.sh && ./build.sh"
  publish = "public"

[[redirects]]
  from = "$VMESS_WSPATH"
  to = "/.netlify/functions/xray?protocol=vmess"
  status = 200

[[redirects]]
  from = "$VLESS_WSPATH"
  to = "/.netlify/functions/xray?protocol=vless"
  status = 200

[[redirects]]
  from = "$TROJAN_WSPATH"
  to = "/.netlify/functions/xray?protocol=trojan"
  status = 200

[[redirects]]
  from = "$SS_WSPATH"
  to = "/.netlify/functions/xray?protocol=ss"
  status = 200
EOF

  mkdir -p public/.netlify/functions
  cat > public/.netlify/functions/xray.js << EOF
const process = require('process')

exports.handler = async (event) => {
  const protocol = event.queryStringParameters.protocol || 'vmess'
  
  // 生成动态配置（示例核心逻辑）
  const config = {
    v: '2',
    ps: 'Netlify_Proxy',
    add: event.headers.host,
    port: '443',
    id: process.env.UUID,
    net: 'ws',
    path: \`/${protocol}\`,
    tls: 'tls'
  }

  return {
    statusCode: 200,
    body: JSON.stringify({
      server: event.headers.host,
      uuid: process.env.UUID,
      protocol: protocol,
      path: \`/${protocol}\`,
      link: \`\${protocol}://\${process.env.UUID}@\${event.headers.host}/path?security=tls\`
    })
  }
}
EOF
}

# 生成前端展示页面
generate_webpage() {
  mkdir -p public
  cat > public/index.html << EOF
<!DOCTYPE html>
<html>
<head>
    <title>Netlify Proxy Service</title>
    <style>
        body { font-family: Arial, sans-serif; max-width: 800px; margin: 0 auto; padding: 20px; }
        .config-box { background: #f5f5f5; padding: 15px; margin: 10px 0; border-radius: 8px; }
    </style>
</head>
<body>
    <h1>Proxy Configurations</h1>
    
    <div class="config-box">
        <h3>VLESS</h3>
        <code id="vless-config"></code>
    </div>

    <script>
        // 动态加载配置
        fetch('/.netlify/functions/xray?protocol=vless')
            .then(res => res.json())
            .then(data => {
                document.getElementById('vless-config').textContent = data.link
            })
    </script>
</body>
</html>
EOF
}

# 构建流程
main() {
  generate_netlify_config
  generate_webpage
  
  # 将UUID写入环境变量
  echo "UUID=$UUID" >> .env
}

main
