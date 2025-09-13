// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";


contract FundMeTest is Test {
    FundMe fundME;

    address USER  = makeAddr("user");
    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant STARTING_BALANCE = 10 ether; 
    uint256 constant GAS_PRICE = 1 ;

    function setUp() external {
        DeployFundMe deployFundMe = new DeployFundMe();
        fundME = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE);
    }

    function testMinimumuSDisFive() public view {
        assertEq(fundME.MINIMUM_USD(), 5e18);
    }

    function testownerIsMsgSender() public view {
        assertEq(fundME.getOwner(), msg.sender);
    }

    function testPriceFeedVersionIsAccurate() public view {
        if (block.chainid == 11155111) {
            uint256 version = fundME.getVersion();
            assertEq(version, 4);
        } else if (block.chainid == 1) {
            uint256 version = fundME.getVersion();
            assertEq(version, 6);
        }
    }

    function testFundFailsWithoutEnoughEth() public {
        vm.expectRevert("You need to spend more ETH!");
        fundME.fund();
    }

    function testFundUpdatesAmountFundedDataStructure() public {
        vm.prank(USER);
        fundME.fund{value: SEND_VALUE}();
        uint256 amountFunded = fundME.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddFunderToArrayOfFunders() public {
        vm.prank(USER);
        fundME.fund{value: SEND_VALUE}();
        address funder = fundME.getFunder(0);
        assertEq(funder, USER);
    }

    modifier funded(){
        vm.prank(USER);
        fundME.fund{value: SEND_VALUE}();
        _;
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.prank(USER);
        vm.expectRevert();
        fundME.withdraw();
    }

    function testWithdrawWithSingleFunder() public funded {
        //Arrange
        uint256 startingOwnerBalance = fundME.getOwner().balance;
        uint256 funderStartingBalance = address(fundME).balance;

        //Act
        vm.prank(fundME.getOwner());//200
        fundME.withdraw(); //should have spent gas

        //Assert

        uint256 endingOwnerBalance = fundME.getOwner().balance;
        uint256 funderEndingBalance = address(fundME).balance;

        assertEq(funderEndingBalance, 0);
        assertEq(endingOwnerBalance, startingOwnerBalance + funderStartingBalance);
    }
       
       //Arrange

    function testWithdrawWithMultipleFunders() public funded {
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 2;
        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            hoax(address(i), SEND_VALUE);
            fundME.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundME.getOwner().balance;
        uint256 funderStartingBalance = address(fundME).balance;

        //Act
        

        vm.startPrank(fundME.getOwner());
        fundME.withdraw();
        vm.stopPrank();
        
        //Assert

        assert(address(fundME).balance == 0);
        assert(funderStartingBalance + startingOwnerBalance == fundME.getOwner().balance);
    }
    function testWithdrawWithMultipleFundersCheaper() public funded  {
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 2;
        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            hoax(address(i), SEND_VALUE);
            fundME.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundME.getOwner().balance;
        uint256 funderStartingBalance = address(fundME).balance;

        //Act
        

        vm.startPrank(fundME.getOwner());
        fundME.cheaperWithdraw();
        vm.stopPrank();
        
        //Assert

        assert(address(fundME).balance == 0);
        assert(funderStartingBalance + startingOwnerBalance == fundME.getOwner().balance);
    }
}
