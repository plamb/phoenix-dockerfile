# Based on https://gist.github.com/edouard-lopez/503d40a5c1a49cf8ae87

# Install dependencies
# these are already included in main dependencies
# apt-get update && apt-get install -y automake libtool build-essential

# Fetch sources
git clone https://github.com/sass/libsass.git
git clone https://github.com/sass/sassc.git libsass/sassc

# Create custom makefiles for **shared library**, for more info read:
# 'Difference between static and shared libraries?' before installing libsass  http://stackoverflow.com/q/2649334/802365
cd libsass
autoreconf --force --install
./configure \
  --disable-tests \
  --enable-shared \
  --prefix=/usr
cd ..

# Build and install the library
make -C libsass -j5 install

# cleanup
rm -rf libasss
apt-get clean
apt-get purge
rm -rf /var/lib/apt/lists/*
