// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IError {
    error SalesHasEnded();
    error TransferFailed();
    error AboveMaximumBuy();
    error BelowMinimumBuy();
    error SaleIsStillActive();
    error RefundFailed(uint256 _refund);
    error IncorrectAmountOfEtherSent();
}
