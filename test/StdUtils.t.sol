// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "../src/StdUtils.sol";
import "../src/Test.sol";

contract StdUtilsMock is StdUtils {
    function bound_(uint256 x, uint256 min, uint256 max) external view returns (uint256 result) {
        result = bound(x, min, max);
    }

    function bound_(int256 x, int256 min, int256 max) external view returns (int256 result) {
        result = bound(x, min, max);
    }

    function bytesToUint_(bytes memory b) external pure returns (uint256) {
        return bytesToUint(b);
    }

    function computeCreateAddress_(address deployer, uint256 nonce) external pure returns (address) {
        return computeCreateAddress(deployer, nonce);
    }

    function computeCreate2Address_(bytes32 salt, bytes32 initcodeHash, address deployer)
        external
        pure
        returns (address)
    {
        return computeCreate2Address(salt, initcodeHash, deployer);
    }

    function getTokenBalances_(address token, address[] memory addresses)
        external
        returns (uint256[] memory balances)
    {
        balances = getTokenBalances(token, addresses);
    }
}

contract StdUtilsTest is Test {
    StdUtilsMock internal utils = new StdUtilsMock();

    /*//////////////////////////////////////////////////////////////////////////
                                    BOUND UINT
    //////////////////////////////////////////////////////////////////////////*/

    function testBound() public {
        assertEq(utils.bound_(uint256(5), 0, 4), 0);
        assertEq(utils.bound_(uint256(0), 69, 69), 69);
        assertEq(utils.bound_(uint256(0), 68, 69), 68);
        assertEq(utils.bound_(uint256(10), 150, 190), 174);
        assertEq(utils.bound_(uint256(300), 2800, 3200), 3107);
        assertEq(utils.bound_(uint256(9999), 1337, 6666), 4669);
    }

    function testBound_WithinRange() public {
        assertEq(utils.bound_(uint256(51), 50, 150), 51);
        assertEq(utils.bound_(uint256(51), 50, 150), bound(utils.bound_(uint256(51), 50, 150), 50, 150));
        assertEq(utils.bound_(uint256(149), 50, 150), 149);
        assertEq(utils.bound_(uint256(149), 50, 150), bound(utils.bound_(uint256(149), 50, 150), 50, 150));
    }

    function testBound_EdgeCoverage() public {
        assertEq(utils.bound_(uint256(0), 50, 150), 50);
        assertEq(utils.bound_(uint256(1), 50, 150), 51);
        assertEq(utils.bound_(uint256(2), 50, 150), 52);
        assertEq(utils.bound_(uint256(3), 50, 150), 53);
        assertEq(utils.bound_(type(uint256).max, 50, 150), 150);
        assertEq(utils.bound_(type(uint256).max - 1, 50, 150), 149);
        assertEq(utils.bound_(type(uint256).max - 2, 50, 150), 148);
        assertEq(utils.bound_(type(uint256).max - 3, 50, 150), 147);
    }

    function testBound_DistributionIsEven(uint256 min, uint256 size) public {
        size = size % 100 + 1;
        min = utils.bound_(min, UINT256_MAX / 2, UINT256_MAX / 2 + size);
        uint256 max = min + size - 1;
        uint256 result;

        for (uint256 i = 1; i <= size * 4; ++i) {
            // x > max
            result = utils.bound_(max + i, min, max);
            assertEq(result, min + (i - 1) % size);
            // x < min
            result = utils.bound_(min - i, min, max);
            assertEq(result, max - (i - 1) % size);
        }
    }

    function testBound(uint256 num, uint256 min, uint256 max) public {
        if (min > max) (min, max) = (max, min);

        uint256 result = utils.bound_(num, min, max);

        assertGe(result, min);
        assertLe(result, max);
        assertEq(result, utils.bound_(result, min, max));
        if (num >= min && num <= max) assertEq(result, num);
    }

    function testBoundUint256Max() public {
        assertEq(utils.bound_(0, type(uint256).max - 1, type(uint256).max), type(uint256).max - 1);
        assertEq(utils.bound_(1, type(uint256).max - 1, type(uint256).max), type(uint256).max);
    }

    function testCannotBoundMaxLessThanMin() public {
        vm.expectRevert(bytes("StdUtils bound(uint256,uint256,uint256): Max is less than min."));
        utils.bound_(uint256(5), 100, 10);
    }

    function testCannotBoundMaxLessThanMin(uint256 num, uint256 min, uint256 max) public {
        vm.assume(min > max);
        vm.expectRevert(bytes("StdUtils bound(uint256,uint256,uint256): Max is less than min."));
        utils.bound_(num, min, max);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      BOUND INT
    //////////////////////////////////////////////////////////////////////////*/

    function testBoundInt() public {
        assertEq(utils.bound_(-3, 0, 4), 2);
        assertEq(utils.bound_(0, -69, -69), -69);
        assertEq(utils.bound_(0, -69, -68), -68);
        assertEq(utils.bound_(-10, 150, 190), 154);
        assertEq(utils.bound_(-300, 2800, 3200), 2908);
        assertEq(utils.bound_(9999, -1337, 6666), 1995);
    }

    function testBoundInt_WithinRange() public {
        assertEq(utils.bound_(51, -50, 150), 51);
        assertEq(utils.bound_(51, -50, 150), bound(utils.bound_(51, -50, 150), -50, 150));
        assertEq(utils.bound_(149, -50, 150), 149);
        assertEq(utils.bound_(149, -50, 150), bound(utils.bound_(149, -50, 150), -50, 150));
    }

    function testBoundInt_EdgeCoverage() public {
        assertEq(utils.bound_(type(int256).min, -50, 150), -50);
        assertEq(utils.bound_(type(int256).min + 1, -50, 150), -49);
        assertEq(utils.bound_(type(int256).min + 2, -50, 150), -48);
        assertEq(utils.bound_(type(int256).min + 3, -50, 150), -47);
        assertEq(utils.bound_(type(int256).min, 10, 150), 10);
        assertEq(utils.bound_(type(int256).min + 1, 10, 150), 11);
        assertEq(utils.bound_(type(int256).min + 2, 10, 150), 12);
        assertEq(utils.bound_(type(int256).min + 3, 10, 150), 13);

        assertEq(utils.bound_(type(int256).max, -50, 150), 150);
        assertEq(utils.bound_(type(int256).max - 1, -50, 150), 149);
        assertEq(utils.bound_(type(int256).max - 2, -50, 150), 148);
        assertEq(utils.bound_(type(int256).max - 3, -50, 150), 147);
        assertEq(utils.bound_(type(int256).max, -50, -10), -10);
        assertEq(utils.bound_(type(int256).max - 1, -50, -10), -11);
        assertEq(utils.bound_(type(int256).max - 2, -50, -10), -12);
        assertEq(utils.bound_(type(int256).max - 3, -50, -10), -13);
    }

    function testBoundInt_DistributionIsEven(int256 min, uint256 size) public {
        size = size % 100 + 1;
        min = utils.bound_(min, -int256(size / 2), int256(size - size / 2));
        int256 max = min + int256(size) - 1;
        int256 result;

        for (uint256 i = 1; i <= size * 4; ++i) {
            // x > max
            result = utils.bound_(max + int256(i), min, max);
            assertEq(result, min + int256((i - 1) % size));
            // x < min
            result = utils.bound_(min - int256(i), min, max);
            assertEq(result, max - int256((i - 1) % size));
        }
    }

    function testBoundInt(int256 num, int256 min, int256 max) public {
        if (min > max) (min, max) = (max, min);

        int256 result = utils.bound_(num, min, max);

        assertGe(result, min);
        assertLe(result, max);
        assertEq(result, utils.bound_(result, min, max));
        if (num >= min && num <= max) assertEq(result, num);
    }

    function testBoundIntInt256Max() public {
        assertEq(utils.bound_(0, type(int256).max - 1, type(int256).max), type(int256).max - 1);
        assertEq(utils.bound_(1, type(int256).max - 1, type(int256).max), type(int256).max);
    }

    function testBoundIntInt256Min() public {
        assertEq(utils.bound_(0, type(int256).min, type(int256).min + 1), type(int256).min);
        assertEq(utils.bound_(1, type(int256).min, type(int256).min + 1), type(int256).min + 1);
    }

    function testCannotBoundIntMaxLessThanMin() public {
        vm.expectRevert(bytes("StdUtils bound(int256,int256,int256): Max is less than min."));
        bound(-5, 100, 10);
    }

    function testCannotBoundIntMaxLessThanMin(int256 num, int256 min, int256 max) public {
        vm.assume(min > max);
        vm.expectRevert(bytes("StdUtils bound(int256,int256,int256): Max is less than min."));
        bound(num, min, max);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    BYTES TO UINT
    //////////////////////////////////////////////////////////////////////////*/

    function testBytesToUint() external {
        bytes memory maxUint = hex"ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff";
        bytes memory two = hex"02";
        bytes memory millionEther = hex"d3c21bcecceda1000000";

        assertEq(utils.bytesToUint_(maxUint), type(uint256).max);
        assertEq(utils.bytesToUint_(two), 2);
        assertEq(utils.bytesToUint_(millionEther), 1_000_000 ether);
    }

    function testCannotConvertGT32Bytes() external {
        bytes memory thirty3Bytes = hex"ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff";
        vm.expectRevert("StdUtils bytesToUint(bytes): Bytes length exceeds 32.");
        utils.bytesToUint_(thirty3Bytes);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                COMPUTE CREATE ADDRESS
    //////////////////////////////////////////////////////////////////////////*/

    function testComputeCreateAddress() external {
        address deployer = 0x6C9FC64A53c1b71FB3f9Af64d1ae3A4931A5f4E9;
        uint256 nonce = 14;
        address createAddress = utils.computeCreateAddress_(deployer, nonce);
        assertEq(createAddress, 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                COMPUTE CREATE2 ADDRESS
    //////////////////////////////////////////////////////////////////////////*/

    function testComputeCreate2Address() external {
        bytes32 salt = bytes32(uint256(31415));
        bytes32 initcodeHash = keccak256(abi.encode(0x6080));
        address deployer = 0x6C9FC64A53c1b71FB3f9Af64d1ae3A4931A5f4E9;
        address create2Address = utils.computeCreate2Address_(salt, initcodeHash, deployer);
        assertEq(create2Address, 0xB147a5d25748fda14b463EB04B111027C290f4d3);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  GET TOKEN BALANCES
    //////////////////////////////////////////////////////////////////////////*/

    address internal USDC_HOLDER = 0xDa9CE944a37d218c3302F6B82a094844C6ECEb17;

    modifier forkMainnet() {
        vm.createSelectFork({urlOrAlias: "mainnet", blockNumber: 16376000});
        _;
    }

    function testCannotGetTokenBalances_NonTokenContract() external forkMainnet {
        // The UniswapV2Factory contract has neither a "balanceOf" function nor a fallback function.
        address token = address(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
        address[] memory addresses = new address[](1);
        addresses[0] = USDC_HOLDER;
        vm.expectRevert();
        utils.getTokenBalances_(token, addresses);
    }
}
