#!/usr/bin/env bash

echo "Downloading ngx_pagespeed ${NGINX_PAGESPEED_VERSION} from https://github.com/pagespeed/ngx_pagespeed/archive/${NGINX_PAGESPEED_VERSION}-${NGINX_PAGESPEED_RELEASE_STATUS}.tar.gz..."

curl -fSL https://github.com/pagespeed/ngx_pagespeed/archive/${NGINX_PAGESPEED_VERSION}-${NGINX_PAGESPEED_RELEASE_STATUS}.tar.gz | tar zxf - -C /tmp

PSOL_URL=$(cat "/tmp/ngx_pagespeed-${NGINX_PAGESPEED_VERSION}-${NGINX_PAGESPEED_RELEASE_STATUS}/PSOL_BINARY_URL")

# The size names must match install/build_psol.sh in mod_pagespeed
if [ "$(uname -m)" = x86_64 ]; then
  PSOL_BIT_SIZE_NAME=x64
else
  PSOL_BIT_SIZE_NAME=ia32
fi

#echo "Downloading ngx_pagespeed PSOL ${NGINX_PAGESPEED_VERSION} from ${PSOL_URL/\$BIT_SIZE_NAME/$PSOL_BIT_SIZE_NAME}..."
curl -fSL https://dl.google.com/dl/page-speed/psol/1.12.34.2-x64.tar.gz | tar xzf - -C /tmp/ngx_pagespeed-${NGINX_PAGESPEED_VERSION}-${NGINX_PAGESPEED_RELEASE_STATUS}

curl -fSL ${PSOL_URL/\$BIT_SIZE_NAME/$PSOL_BIT_SIZE_NAME} | tar xzf - -C /tmp/ngx_pagespeed-${NGINX_PAGESPEED_VERSION}-${NGINX_PAGESPEED_RELEASE_STATUS}
