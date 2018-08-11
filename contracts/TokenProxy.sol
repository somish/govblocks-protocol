pragma solidity 0.4.24;

import "./GBTStandardToken.sol";
import "./imports/openzeppelin-solidity/contracts/math/SafeMath.sol";


contract TokenProxy {
	using SafeMath for uint256;

	GBTStandardToken public originalToken;

	constructor(address _originalToken) public {
        originalToken = GBTStandardToken(_originalToken);
    }


    function totalSupply() public view returns(uint) {
    	return originalToken.totalSupply();
    }

    function balanceOf(address _of) public view returns(uint) {
    	return originalToken.balanceOf(_of);
    }

    function name() public view returns(string) {
    	return originalToken.name();
    }

    function symbol() public view returns(string) {
    	return originalToken.symbol();
    }

    function decimals() public view returns(uint8) {
    	return originalToken.decimals();
    }


    /**
     * @dev Reasons why a user's tokens have been locked
     */
    mapping(address => bytes32[]) public lockReason;

    struct lockToken {
        uint256 amount;
        uint256 validity;
        bool claimed;
    }

    /**
     * @dev Holds number & validity of tokens locked for a given reason for
     *      a given member address
     */
    mapping(address => mapping(bytes32 => lockToken)) public locked;

    event Lock(
        address indexed _of,
        bytes32 indexed _reason,
        uint256 _amount,
        uint256 _validity
    );

    /**
     * @dev Records data of all the tokens unlocked
     */
    event Unlocked(
        address indexed _of,
        bytes32 indexed _reason,
        uint256 _amount
    );
    
    /**
     * @dev Locks a specified amount of tokens against an address,
     *      for a specified reason and time
     * @param _reason The reason to lock tokens
     * @param _amount Number of tokens to be locked
     * @param _time Lock time in seconds
     */
    function lock(bytes32 _reason, uint256 _amount, uint256 _time)
        public
        returns (bool)
    {
        uint256 validUntil = block.timestamp.add(_time);
        // If tokens are already locked, the functions extendLock or
        // increaseLockAmount should be used to make any changes
        require(tokensLocked(msg.sender, _reason) == 0);
        require(_amount != 0);
        //require(_amount <= balances[msg.sender]); SafeMath.sub will throw.
        originalToken.transferFrom(msg.sender, address(this), _amount);
        if (locked[msg.sender][_reason].amount == 0)
            lockReason[msg.sender].push(_reason);
        locked[msg.sender][_reason] = lockToken(_amount, validUntil, false);
        emit Lock(msg.sender, _reason, _amount, validUntil);
        return true;
    }

    /**
     * @dev Returns tokens locked for a specified address for a
     *      specified reason
     *
     * @param _of The address whose tokens are locked
     * @param _reason The reason to query the lock tokens for
     */
    function tokensLocked(address _of, bytes32 _reason)
        public
        view
        returns (uint256 amount)
    {
        if (!locked[_of][_reason].claimed)
            amount = locked[_of][_reason].amount;
    }
    
    /**
     * @dev Returns tokens locked for a specified address for a
     *      specified reason at a specific time
     *
     * @param _of The address whose tokens are locked
     * @param _reason The reason to query the lock tokens for
     * @param _time The timestamp to query the lock tokens for
     */
    function tokensLockedAtTime(address _of, bytes32 _reason, uint256 _time)
        public
        view
        returns (uint256 amount)
    {
        if (locked[_of][_reason].validity > _time)
            amount = locked[_of][_reason].amount;
    }

    /**
     * @dev Returns total tokens held by an address (locked + transferable)
     * @param _of The address to query the total balance of
     */
    function totalBalanceOf(address _of)
        public
        view
        returns (uint256 amount)
    {
        uint256 lockedAmount;
        for (uint256 i = 0; i < lockReason[_of].length; i++) {
            lockedAmount += tokensLocked(_of, lockReason[_of][i]);
        }   
        amount = balanceOf(_of).add(lockedAmount);
        return amount;
    }    
    
    /**
     * @dev Extends lock for a specified reason and time
     * @param _reason The reason to lock tokens
     * @param _time Lock extension time in seconds
     */
    function extendLock(bytes32 _reason, uint256 _time)
        public
        returns (bool)
    {
        require(tokensLockedAtTime(msg.sender, _reason, block.timestamp) > 0);
        locked[msg.sender][_reason].validity += _time;
        emit Lock(msg.sender, _reason, locked[msg.sender][_reason].amount, locked[msg.sender][_reason].validity);
        return true;
    }
    
    /**
     * @dev Increase number of tokens locked for a specified reason
     * @param _reason The reason to lock tokens
     * @param _amount Number of tokens to be increased
     */
    function increaseLockAmount(bytes32 _reason, uint256 _amount)
        public
        returns (bool)
    {
        require(tokensLockedAtTime(msg.sender, _reason, block.timestamp) > 0);
        originalToken.transferFrom(msg.sender, address(this), _amount);
        locked[msg.sender][_reason].amount += _amount;
        emit Lock(msg.sender, _reason, locked[msg.sender][_reason].amount, locked[msg.sender][_reason].validity);
        return true;
    }

    /**
     * @dev Returns unlockable tokens for a specified address for a specified reason
     * @param _of The address whose tokens are locked
     * @param _reason The reason to query the lock tokens for
     */
    function tokensUnlockable(address _of, bytes32 _reason)
        public
        view
        returns (uint256 amount)
    {
        if (locked[_of][_reason].validity <= now && !locked[_of][_reason].claimed)
            amount = locked[_of][_reason].amount;
    }

    /**
     * @dev Unlocks the locked tokens
     * @param _of Address of person, claiming back the tokens
     */
    function unlock(address _of)
        public
        returns (uint256 unlockableTokens)
    {
        uint lockedTokens;
        for (uint256 i = 0; i < lockReason[_of].length; i++) {
            lockedTokens = tokensUnlockable(_of, lockReason[_of][i]);
            if (lockedTokens > 0) {
                unlockableTokens += lockedTokens;
                locked[_of][lockReason[_of][i]].claimed = true;
                emit Unlocked(_of, lockReason[_of][i], lockedTokens);
            }
        }  
        if(unlockableTokens > 0) {
            originalToken.transfer(_of, unlockableTokens);
        } 
    }

    /**
     * @dev gets unlockable tokens of a person
     * @param _of Address of person, claiming back the tokens
     */
    function getUnlockableTokens(address _of)
        public
        view
        returns (uint256 unlockableTokens)
    {
        for (uint256 i = 0; i < lockReason[_of].length; i++) {
            unlockableTokens += tokensUnlockable(_of, lockReason[_of][i]);
        }  
    }
}