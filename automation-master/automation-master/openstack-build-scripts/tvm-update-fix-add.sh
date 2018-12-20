#!/bin/bash

sed -i '/g.set_backend("direct")/a\    ls = ["force_tcg"] \n    g.set_backend_settings(ls)'  /opt/stack/contego/install-scripts/tvault-contego-install.sh

