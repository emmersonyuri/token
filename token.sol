// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts@4.4.0/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts@4.4.0/access/Ownable.sol";

contract DeflationaryToken is ERC20, Ownable {
    uint256 public burnRate; // Taxa de queima
    uint256 public maxBurnPercent; // Percentual máximo de tokens a serem queimados
    uint256 public buySellTax; // Taxa de 1% de compra e venda
    address public marketingWallet = 0xE23E00e9aeBeBd1b444E5Fc0A348158e6fB1942d; // Carteira de marketing e desenvolvimento

    mapping(address => bool) private _isExcludedFromFees; // Mapeamento de endereços isentos de taxas

    // Variável para rastrear o total de tokens queimados
    uint256 private _totalBurned;

    // Passando msg.sender para o construtor de Ownable
    constructor() ERC20("DeflationaryToken", "DFT") Ownable() {
        _mint(msg.sender, 1000000 * 10**18); // Mintando 1 milhão de tokens ao deployer
        burnRate = 1; // 1% por transação
        maxBurnPercent = 50; // Limite de 50% de queima total do supply
        buySellTax = 1; // 1% de taxa de compra/venda
        _isExcludedFromFees[owner()] = true; // Proprietário isento de taxas
        _isExcludedFromFees[address(this)] = true; // Contrato isento de taxas
    }

    function _burnControlled(address sender, uint256 amount) internal {
        uint256 burnAmount = (amount * burnRate) / 100;

        // Queima máxima de 50% do supply total
        if (
            burnAmount + totalBurned() <= (totalSupply() * maxBurnPercent) / 100
        ) {
            _burn(sender, burnAmount);
            // Atualiza o total de tokens queimados
            _totalBurned += burnAmount;
        }
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 transferAmount = amount;

        // Aplicar queima controlada e taxas somente para transferências normais
        if (!_isExcludedFromFees[sender] && !_isExcludedFromFees[recipient]) {
            // Aplicar taxa de 1% de marketing e desenvolvimento
            uint256 marketingFee = (amount * buySellTax) / 100;
            transferAmount = amount - marketingFee;

            // Transferir taxa para carteira de marketing
            super._transfer(sender, marketingWallet, marketingFee);

            // Aplicar queima controlada
            _burnControlled(sender, amount);
        }

        // Realiza a transferência normal
        super._transfer(sender, recipient, transferAmount);
    }

    // Sobrescrevendo a função _beforeTokenTransfer do ERC20
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        // Aqui você pode adicionar lógica personalizada que deve ser executada antes de qualquer transferência
        // Por exemplo, atualizar saldos de staking ou aplicar restrições adicionais
    }

    // Excluir endereço de taxas e queima (como exchanges ou contratos de staking)
    function excludeFromFees(address account, bool excluded)
        external
        onlyOwner
    {
        _isExcludedFromFees[account] = excluded;
    }

    // Função para ajustar a taxa de queima
    function setBurnRate(uint256 newRate) external onlyOwner {
        require(newRate <= 5, "Burn rate can't exceed 5%");
        burnRate = newRate;
    }

    // Função para ajustar o percentual máximo de tokens que podem ser queimados
    function setMaxBurnPercent(uint256 percent) external onlyOwner {
        require(percent <= 50, "Max burn percent cannot exceed 50%");
        maxBurnPercent = percent;
    }

    // Função para ajustar a taxa de compra e venda
    function setBuySellTax(uint256 newTax) external onlyOwner {
        require(newTax <= 5, "Buy/sell tax can't exceed 5%");
        buySellTax = newTax;
    }

    // Função para verificar se um endereço está excluído de taxas
    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    // Função para retornar o total de tokens queimados
    function totalBurned() public view returns (uint256) {
        return _totalBurned;
    }

    // Função de fallback para aceitar ETH (ou BNB) caso seja necessário
    receive() external payable {}
}
