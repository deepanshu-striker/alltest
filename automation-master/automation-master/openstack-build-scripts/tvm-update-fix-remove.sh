#!/bin/bash -x

sed -i '/force_tcg/ d' /opt/stack/contego/install-scripts/tvault-contego-install.sh
sed -i '/set_backend_settings/ d' /opt/stack/contego/install-scripts/tvault-contego-install.sh
