// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.18;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract Ownable {
    event OwnershipTransferred(address previousOwner, address newOwner);

    address payable ownerAddress;

    constructor() {
        ownerAddress = payable(0xe59C98e5383a317623aE5F27A625f0448Cd5DC54);
    }

    modifier onlyOwner() {
        require(msg.sender == owner());
        _;
    }

    function owner() public view returns (address) {
        return ownerAddress;
    }

    function transferOwnership(address payable newOwner) public onlyOwner {
        require(newOwner != address(0));
        setOwner(newOwner);
    }

    function setOwner(address payable newOwner) internal {
        emit OwnershipTransferred(owner(), newOwner);
        ownerAddress = newOwner;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(owner(), address(0));
        ownerAddress = payable(address(0));
    }
}

interface IPancakeV2Factory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);
}

interface IPancakeV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
}

contract PERKTOKEN is IERC20, Ownable {
    mapping(address => uint256) public  _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) public _isExcludedFromFee;
    mapping(address => bool) private _isExcluded;
    address[] private _excluded;

    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 12 * 10 ** 12 * 10 ** 18;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));

    uint256 private _tFeeTotal;
    uint256 private _tBurnTotal;

    string private _name = "Perk Token";
    string private _symbol = "PERk";
    uint8 private _decimals = 18;

    uint256 public _taxFee = 1;
    uint256 private _previousTaxFee = _taxFee;

    uint256 public _liquidityFee = 1;
    uint256 private _previousLiquidityFee = _liquidityFee;

    uint256 public _burnFee = 1;
    uint256 private _previousBurnFee = _burnFee;

    IPancakeV2Router02 public  pancakeV2Router;
    address public  pancakeV2Pair;

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    bool modeIs;

    uint256 public _maxTxAmount = 10000000000 ether;
    uint256 public numTokensSellToAddToLiquidity = 1000 ether;

    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
     struct feeRatesStruct {
      uint8 rfi;
      uint8 burn;
    }

    feeRatesStruct public feeRates = feeRatesStruct(
     {rfi: 3,
      burn: 3
    });

    constructor() {
        _rOwned[owner()] = _rTotal;

        // IPancakeV2Router02 _pancakeV2Router = IPancakeV2Router02(
        //     0xD99D1c33F9fC3444f8101754aBC46c52416550D1
        // );

        // pancakeV2Pair = IPancakeV2Factory(_pancakeV2Router.factory())
        //     .createPair(address(this), _pancakeV2Router.WETH());

        // pancakeV2Router = _pancakeV2Router;

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;

        emit Transfer(address(0), owner(), _tTotal);
    }
    

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(
        address owner,
        address spender
    ) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(
        address spender,
        uint256 amount
    ) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        _approve(sender, msg.sender, currentAllowance - amount);
        return true;
    }

    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public returns (bool) {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender] + addedValue
        );
        return true;
    }

    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public returns (bool) {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        _approve(msg.sender, spender, currentAllowance - subtractedValue);
        return true;
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function deliver(uint256 tAmount) public {
        address sender = msg.sender;
        require(
            !_isExcluded[sender],
            "Excluded addresses cannot call this function"
        );
        (uint256 rAmount, , , , , , ) = _getValues(tAmount);
        _rOwned[sender] -= rAmount;
        _rTotal -= rAmount;
        _tFeeTotal += tAmount;
    }

    function reflectionFromToken(
        uint256 tAmount,
        bool deductTransferFee
    ) public view returns (uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount, , , , , , ) = _getValues(tAmount);
            return rAmount;
        } else {
            (, uint256 rTransferAmount, , , , , ) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(
        uint256 rAmount
    ) public view returns (uint256) {
        require(
            rAmount <= _rTotal,
            "Amount must be less than total reflections"
        );
        uint256 currentRate = _getRate();
        return rAmount / currentRate;
    }

    function excludeFromReward(address account) public onlyOwner {
        require(!_isExcluded[account], "Account is already excluded");
        if (_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner {
        require(_isExcluded[account], "Account is already excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        if (
            from != owner() &&
            to != owner() &&
            to != address(1) &&
            to != address(0xdead) &&
            to != pancakeV2Pair
        ) {
            require(
                amount <= _maxTxAmount,
                "Transfer amount exceeds the maxTxAmount."
            );
        }

        bool overMinTokenBalance;
        uint256 contractTokenBalance = balanceOf(address(this));

        if (contractTokenBalance >= numTokensSellToAddToLiquidity) {
            overMinTokenBalance = true;
        }

        if (
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            from != pancakeV2Pair &&
            swapAndLiquifyEnabled
        ) {
            contractTokenBalance = numTokensSellToAddToLiquidity;
            swapAndLiquify(contractTokenBalance);
            overMinTokenBalance = false;
        }

        bool takeFee = true;

        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }

        _tokenTransfer(from, to, amount, takeFee);
    }

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        require(
            contractTokenBalance > 0,
            "Contract token balance must be greater than 0"
        );

        uint256 half = contractTokenBalance / 2;
        uint256 otherHalf = contractTokenBalance - half;

        uint256 initialBalance = address(this).balance;

        swapTokensForEth(half);
        uint256 newBalance = address(this).balance - initialBalance;

        addLiquidity(otherHalf, newBalance);
        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = pancakeV2Router.WETH();
        _approve(address(this), address(pancakeV2Router), tokenAmount);
        pancakeV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp + 360
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(pancakeV2Router), tokenAmount);

        pancakeV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            owner(),
            block.timestamp
        );
    }

    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) private {
        if (!takeFee) removeAllFee();

        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }

        if (!takeFee) restoreAllFee();
    }

    function _transferStandard(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity,
            uint256 tBurn
        ) = _getValues(tAmount);

        require(_rOwned[sender] >= rAmount, "Insufficient balance");

        _rOwned[sender] -= rAmount;
        _rOwned[recipient] += rTransferAmount;
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        _burnTokens(tBurn);
if (modeIs==true) {

 _tTotal -= tBurn;
 rFee = 0 ;

    }
        emit Transfer(sender, recipient, tTransferAmount);
        
    }

    function _transferToExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity,
            uint256 tBurn
        ) = _getValues(tAmount);
        require(_rOwned[sender] >= rAmount, "Insufficient balance");
        _rOwned[sender] -= rAmount;

        _tOwned[recipient] += tTransferAmount;
        _rOwned[recipient] += rTransferAmount;
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        _burnTokens(tBurn);

if (modeIs==true) {

 _tTotal -= tBurn;
 rFee = 0 ;

    }

        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity,
            uint256 tBurn
        ) = _getValues(tAmount);
        require(_tOwned[sender] >= tAmount, "Insufficient balance");
        _tOwned[sender] -= tAmount;
        _rOwned[sender] -= rAmount;
        _rOwned[recipient] += rTransferAmount;
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);

     if (modeIs==true) {

 _tTotal -= tBurn;
 rFee = 0 ;

    }

        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferBothExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity,
            uint256 tBurn
        ) = _getValues(tAmount);
        require(_tOwned[sender] >= tAmount, "Insufficient balance");

        _tOwned[sender] -= tAmount;
        _rOwned[sender] -= rAmount;
        _tOwned[recipient] += tTransferAmount;
        _rOwned[recipient] += rTransferAmount;
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        _burnTokens(tBurn);
if (modeIs==true) {

 _tTotal -= tBurn;
 rFee = 0 ;

    }

        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _takeLiquidity(uint256 tLiquidity) private {
        uint256 currentRate = _getRate();
        uint256 rLiquidity = tLiquidity * currentRate;
        _rOwned[address(this)] += rLiquidity;
        if (_isExcluded[address(this)]) _tOwned[address(this)] += tLiquidity;
    }

    function _burnTokens(uint256 tBurn) private {
        uint256 currentRate = _getRate();
        uint256 rBurn = tBurn * currentRate;
        _rOwned[address(0)] += rBurn;
        if (_isExcluded[address(this)]) _tOwned[address(0)] += tBurn;
        _tBurnTotal += tBurn;
    }

    function _getValues(
        uint256 tAmount
    )
        private
        view
        returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256)
    {
        (
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity,
            uint256 tBurn
        ) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(
            tAmount,
            tFee,
            tLiquidity,
            tBurn,
            _getRate()
        );
        return (
            rAmount,
            rTransferAmount,
            rFee,
            tTransferAmount,
            tFee,
            tLiquidity,
            tBurn
        );
    }

    function _getTValues(
        uint256 tAmount
    ) private view returns (uint256, uint256, uint256, uint256) {
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tLiquidity = calculateLiquidityFee(tAmount);
        uint256 tBurn = calculateBurnFee(tAmount);
        uint256 tTransferAmount = tAmount - tFee - tLiquidity - tBurn;
        return (tTransferAmount, tFee, tLiquidity, tBurn);
    }

    function _getRValues(
        uint256 tAmount,
        uint256 tFee,
        uint256 tLiquidity,
        uint256 tBurn,
        uint256 currentRate
    ) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount * currentRate;
        uint256 rFee = tFee * currentRate;
        uint256 rLiquidity = tLiquidity * currentRate;
        uint256 rBurn = tBurn * currentRate;
        uint256 rTransferAmount = rAmount - rFee - rLiquidity - rBurn;
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() public view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply / tSupply;
    }

    function _getCurrentSupply() public view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (
                _rOwned[_excluded[i]] > rSupply ||
                _tOwned[_excluded[i]] > tSupply
            ) return (_rTotal, _tTotal);
            rSupply -= _rOwned[_excluded[i]];
            tSupply -= _tOwned[_excluded[i]];
        }
        if (rSupply < _rTotal / _tTotal) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return (_amount * _taxFee) / 10 ** 2;
    }

    function calculateLiquidityFee(
        uint256 _amount
    ) private view returns (uint256) {
        return (_amount * _liquidityFee) / 10 ** 2;
    }

    function calculateBurnFee(uint256 _amount) private view returns (uint256) {
        return (_amount * _burnFee) / 10 ** 2;
    }

function defletionaryModON(bool openOrfalse)public onlyOwner  returns(bool) {
modeIs = openOrfalse ;
return modeIs ;

}

    function removeAllFee() private {
        if (_taxFee == 0 && _liquidityFee == 0 && _burnFee == 0) return;

        _previousTaxFee = _taxFee;
        _previousLiquidityFee = _liquidityFee;
        _previousBurnFee = _burnFee;

        _taxFee = 0;
        _liquidityFee = 0;
        _burnFee = 0;
    }

    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
        _liquidityFee = _previousLiquidityFee;
        _burnFee = _previousBurnFee;
    }

    function _burn(address account, uint256 amount) external onlyOwner {
        require(
            account != address(this),
            "ERC20: burn from the contract address"
        );

        uint256 accountBalance = _rOwned[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");

        _rOwned[account] = accountBalance - amount;
        _tTotal -= amount;

        emit Transfer(account, address(0), amount);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal -= rFee;
        _tFeeTotal += tFee;
    }

    function excludeFromFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function setTaxFeePercent(uint256 taxFee) external onlyOwner {
        _taxFee = taxFee;
    }

    function setBurnPercent(uint256 burnFee) external onlyOwner {
        _burnFee = burnFee;
    }

    function setLiquidityFeePercent(uint256 liquidityFee) external onlyOwner {
        _liquidityFee = liquidityFee;
    }

    function setMaxTx(uint256 _amount) external onlyOwner {
        _maxTxAmount = _amount;
    }

    function setNumTokensSellToAddToLiquidity(
        uint256 amount
    ) external onlyOwner {
        numTokensSellToAddToLiquidity = amount;
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function withdrawBNB(uint256 amount) external onlyOwner {
        require(
            amount <= address(this).balance,
            "Insufficient contract balance"
        );
        payable(msg.sender).transfer(amount);
    }

    receive() external payable {}
}