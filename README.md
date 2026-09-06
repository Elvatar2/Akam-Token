# Akam Token (AKAM)

A simple, immutable ERC-20 token built on Polygon with a fixed supply.

## 📊 Token Specifications

| Property | Value |
| :--- | :--- |
| **Name** | Akam |
| **Symbol** | AKAM |
| **Network** | Polygon PoS |
| **Standard** | ERC-20 |
| **Total Supply** | 400,000,000 AKM |
| **Decimals** | 18 |
| **Mintable** | ❌ No (Fixed Forever) |

## 🛠️ Development

This project uses [Foundry](https://book.getfoundry.sh/).

### Install Dependencies
```bash
forge install
```

### Build
```bash
forge build
```

### Run Tests
```bash
forge test
```

### Format Code
```bash
forge fmt
```

## 📂 Project Structure

```text
Akam-Token/
├── contracts/
│   └── AkamToken.sol       # Core ERC-20 Token Contract
├── test/
│   └── AkamToken.t.sol     # Unit tests for the token
├── .gitignore
├── foundry.toml
├── remappings.txt
└── README.md
```

## 📄 License

MIT