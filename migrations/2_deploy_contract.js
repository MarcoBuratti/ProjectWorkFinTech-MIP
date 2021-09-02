const Migrations = artifacts.require("EcommToken")

module.exports = function (deployer) {
  deployer.deploy(Migrations);
};
