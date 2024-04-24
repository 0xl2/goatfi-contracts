// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { SafeERC20, IERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { BaseAllToNativeStrat } from "../common/BaseAllToNativeStrat.sol";
import { IAuraBooster, IBaseRewardPool } from "interfaces/aura/IAura.sol";

contract StrategyAura is BaseAllToNativeStrat {
    using SafeERC20 for IERC20;

    IAuraBooster public constant booster = IAuraBooster(0x98Ef32edd24e2c92525E59afc4475C1242a30184);

    address public rewardPool;
    uint256 public pid;

    function initialize(
        uint _pid,
        address _native,
        address _depositToken,
        address[] calldata _rewards,
        CommonAddresses calldata _commonAddresses
    ) public initializer {
        pid = _pid;
        IAuraBooster.PoolInfo memory pInfo = booster.poolInfo(pid);
        require(!pInfo.shutdown, "!shutdown");

        rewardPool = pInfo.crvRewards;

        __BaseStrategy_init(pInfo.lptoken, _native, _rewards, _commonAddresses);
        setDepositToken(_depositToken);
        setHarvestOnDeposit(true);
    }

    function balanceOfPool() public view override returns (uint256) {
        return IERC20(rewardPool).balanceOf(address(this));
    }

    function _deposit(uint amount) internal override {
        bool flag = booster.deposit(pid, amount, true);
        require(flag, "!deposit");
    }

    function _withdraw(uint amount) internal override {
        bool flag = IBaseRewardPool(rewardPool).withdrawAndUnwrap(amount, false);
        require(flag, "!withdraw");
    }

    function _emergencyWithdraw() internal override {
        IBaseRewardPool(rewardPool).withdrawAllAndUnwrap(false);
    }

    function _claim() internal override {
        bool flag = IBaseRewardPool(rewardPool).getReward();
        require(flag, "!claim");
    }

    function _verifyRewardToken(address token) internal view override {
        require(token != address(booster) && token != rewardPool, "!rewardToken");
    }

    function _giveAllowances() internal override {
        IERC20(want).forceApprove(address(booster), type(uint).max);
        IERC20(native).forceApprove(unirouter, type(uint).max);
    }

    function _removeAllowances() internal override {
        IERC20(want).forceApprove(address(booster), 0);
        IERC20(native).forceApprove(unirouter, 0);
    }
}
