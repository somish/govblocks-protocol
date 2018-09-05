[![Build Status](https://travis-ci.org/somish/govblocks-protocol.svg?branch=master)](https://travis-ci.org/somish/govblocks-protocol)
[![Coverage Status](https://coveralls.io/repos/github/somish/govblocks-protocol/badge.svg?branch=master)](https://coveralls.io/github/somish/govblocks-protocol?branch=master)
[![GitHub issues](https://img.shields.io/github/issues/somish/govblocks-protocol.svg)](https://github.com/somish/govblocks-protocol/issues)


# GovBlocks
GovBlocks is an open permissionless protocol for blockchain applications. This repo showcases the reference implementation of the GovBlocks protocol.

## Getting Started

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes. 


### Requirements
```
Node >= 7.6
```


### Installing
Firstly, you need to clone this repo. You can do so by downloading the repo as a zip and unpacking or using the following git command

```
git clone https://github.com/somish/govblocks-protocol.git
```

Now, It's time to install the dependencies. Enter the govblocks-protocol directory and use

```
npm install
```
We need to compile the contracts before deploying. We'll be using truffle for that (You can use Remix or solc directly).
```
truffle compile
```
Now, You should start a private network on port 7545 using Ganache or something similar. Then, you can deploy your GovBlocks dApp using the migrate script.
```
truffle deploy
```
You can use public networks as well but you will have to do the initialization manually as the contracts will pick up the official addresses otherwise. We recommend using the GovBlocks UI if you wish to test on a public network.

If you want, you can run the test cases using
```
truffle test
```


## Contributing
You can contribute to this project by forking it, commiting the changes to your fork and then creating a pull request.
