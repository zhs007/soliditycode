pragma solidity ^0.4.11;

// PiggybankGameBase
contract PiggybankGameBase {
    struct Piggybank {
        uint ranking;
        address player;
        uint price;
        uint totalFeed;
        uint lastFeed;
        bool exclude;
    }

    // game name
    string gameName;
    // piggybank pool
    mapping (uint => Piggybank) poolPiggybank;
    uint totalPiggybankNums;
    // game master
    address gameMaster;

    uint64 seedRandom = 0;

    modifier canViewPiggybankSecret(uint piggybankid) {
        require(msg.sender == gameMaster || msg.sender == poolPiggybank[piggybankid - 1].player);
        _;
    }

    modifier onlyGameMaster() {
        require(msg.sender == gameMaster);
        _;
    }    

    function PiggybankGameBase(string _gameName, uint _nums) public payable {
        totalPiggybankNums = _nums;
        seedRandom = uint64(keccak256(keccak256(block.blockhash(block.number), seedRandom), now));
        gameName = _gameName;
        gameMaster = msg.sender;
        uint price = msg.value / totalPiggybankNums;
        for (uint i = 1; i <= totalPiggybankNums; ++i) {
            poolPiggybank[i].ranking = 1;
            poolPiggybank[i].player = gameMaster;
            poolPiggybank[i].price = price;
            poolPiggybank[i].totalFeed = 0;
            poolPiggybank[i].lastFeed = 0;
            poolPiggybank[i].exclude = false;
        }
    }

    function random(uint64 _upper) internal returns (uint64) {
        seedRandom = uint64(keccak256(keccak256(block.blockhash(block.number), seedRandom), now));
        return seedRandom % _upper;
    }

    function getWinPool() external view returns (uint) {
        return this.balance;
    }

    function getPiggybank_TotalFeed(uint piggybankid) external view canViewPiggybankSecret(piggybankid) returns (uint) {
        return poolPiggybank[piggybankid].price;
    }

    function sortPiggybank(uint[] arr, uint left, uint right) internal {
        uint i = left;
        uint j = right;
        uint pivot = poolPiggybank[arr[left + (right - left) / 2]].totalFeed;
        while (i <= j) {
            while (poolPiggybank[arr[i]].totalFeed < pivot) {
                i++;
            }

            while (pivot < poolPiggybank[arr[j]].totalFeed) {
                j--;
            }

            if (i <= j) {
                (arr[i], arr[j]) = (arr[j], arr[i]);
                i++;
                j--;
            }
        }
        if (left < j)
            sortPiggybank(arr, left, j);
        if (i < right)
            sortPiggybank(arr, i, right);
    }

    function runToday() external onlyGameMaster() {
        uint[] memory lstRanking = new uint[](totalPiggybankNums);
        for (uint i = 1; i <= totalPiggybankNums; ++i) {
            if (!poolPiggybank[i].exclude) {
                poolPiggybank[i].lastFeed = 0;

                poolPiggybank[i].totalFeed += random(100000);
            }

            lstRanking[i - 1] = i;
        }

        sortPiggybank(lstRanking, 0, totalPiggybankNums - 1);
    }
}