// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "hardhat/console.sol";
import {IError} from "./interfaces/IError.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title initial coin offering
 */
contract ICO is Ownable, IError {
    IERC20 public token;

    uint256 private constant DISCOUNT_RATE = 5;
    uint256 private constant TO_WEI = 10 ** 18;
    uint256 private constant MINIMUM_BUY_IN_TOKEN = 10000;

    uint256 private constant MAXIMUM_BUY_IN_TOKEN = 100000;
    uint256 private constant STARTING_PRICE = 5 * 10 ** 14; // for each token

    uint256 private constant TARGET = 50 ether;
    uint256 private constant DURATION = 7 days;

    uint256 private immutable END_TIME;
    uint256 private immutable START_TIME;

    uint256 public contractBalance;

    mapping(address => uint256) private amountOfTokenPurchased;

    receive() external payable {}

    constructor(address _token) {
        START_TIME = block.timestamp;
        END_TIME = START_TIME + DURATION;
        token = IERC20(_token);
    }

    /**
     *  @notice calculate the current price of each token
     *  @dev calculate the time difference from the time sale started to the time of query
     *       decreaseSinceStart calculate the amount of token to be reduced per day
     *       totalDecrement reduce the amount by 5% of the initial sales price
     *  @return the current sale price at time of query
     */
    function getCurrentPrice() public view returns (uint256) {
        uint256 timeDiff = block.timestamp - START_TIME; // 1 days
        uint256 decreaseSinceStart = timeDiff / 1 days; //  reduce the price at every 24 hours
        uint256 totalDecrement = (decreaseSinceStart *
            (DISCOUNT_RATE * STARTING_PRICE)) / 100; // reduce by 5% of initial price6
        return STARTING_PRICE - totalDecrement;
    }

    /**
     * @param _quantity the amount of token the contract caller is buying
     */
    function buy(uint256 _quantity) external payable {
        uint256 price = getCurrentPrice();
        uint256 cb = contractBalance;
        if (
            amountOfTokenPurchased[msg.sender] + _quantity * TO_WEI >
            MAXIMUM_BUY_IN_TOKEN * TO_WEI
        ) revert AboveMaximumBuy();
        if (block.timestamp > END_TIME) revert SalesHasEnded();
        if (_quantity < MINIMUM_BUY_IN_TOKEN) revert BelowMinimumBuy();
        if (_quantity * price != msg.value) revert IncorrectAmountOfEtherSent();
        uint256 toBeSent;
        unchecked {
            cb += msg.value;

            if (cb > TARGET) {
                uint256 refund = cb - TARGET;
                (bool success, ) = payable(msg.sender).call{value: refund}("");
                if (!success) revert RefundFailed(refund);
                toBeSent = (msg.value - refund) / price;
                cb -= refund;
            } else toBeSent = _quantity * TO_WEI;

            amountOfTokenPurchased[msg.sender] += toBeSent;
            contractBalance = cb;
        }

        emit Buy(msg.sender, toBeSent);
        require(token.transfer(msg.sender, toBeSent));
    }

    function withdraw() external onlyOwner {
        if (block.timestamp < END_TIME) revert SaleIsStillActive();
        contractBalance = 0;
        require(token.transfer(msg.sender, token.balanceOf(address(this))));
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        if (!success) revert TransferFailed();
    }

    function getAmountOfTokenPurchased(
        address _addr
    ) external view returns (uint256) {
        return amountOfTokenPurchased[_addr];
    }

    event Buy(address buyer, uint256 amount);
}
