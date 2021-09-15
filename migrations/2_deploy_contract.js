const Migrations = artifacts.require("AmazonCurrency")

module.exports = function (deployer) {
  deployer.deploy(Migrations);
};
