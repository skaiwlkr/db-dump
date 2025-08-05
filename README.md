# 📦 DB Transfer

**DB Transfer** is a simple Bash script to transfer PostgreSQL databases.  
It allows you to:

- Create dumps of a source or target database
- Perform a full transfer (dump + restore) from one database to another

Ideal for development, testing, or backup purposes.


## 🚀 Features

- Easy CLI usage via Bash
- Uses standard PostgreSQL tools (`pg_dump`, `psql`)
- Supports dump-only or full transfer modes
- Automatically removes temporary dump files
- Confirmation prompt before destructive operations


## ⚙️ Requirements

- **Bash**
- **PostgreSQL CLI tools** (`pg_dump`, `psql`)
- Access to both databases via URI (e.g. `postgresql://user:pass@host/dbname`)


## 📁 Project Structure

```
.
├── db-transfer.sh        # Main script
├── .env.transfer         # Example environment config (do not commit your own!)
└── README.md             # This file
```


## 🛠️ Setup

1. **Clone the repository**

```bash
git clone https://github.com/your-username/db-transfer.git
cd db-transfer
```

2. **Create your own environment config**

```bash
cp .env.transfer.example .env.transfer
```

Edit `.env.transfer`:

```env
SOURCE_DB_URL="postgresql://USERNAME:PASSWORD@HOST/SOURCE_DB?sslmode=require"
TARGET_DB_URL="postgresql://USERNAME:PASSWORD@HOST/TARGET_DB"
```

> ⚠️ Do **not** commit `.env.transfer` to version control!


## 🧪 Usage

### 🔁 Full transfer (dump & restore)

```bash
./db-transfer.sh --restore
```

Steps:
1. Creates a dump from `SOURCE_DB_URL`
2. Prompts for confirmation before resetting the target schema
3. Drops and recreates the `public` schema in `TARGET_DB_URL`
4. Restores the dump to the target database
5. Deletes the temporary dump file


### 💾 Dump only

#### Dump from source

```bash
./db-transfer.sh --dump SOURCE
```

#### Dump from target

```bash
./db-transfer.sh --dump TARGET
```


## 🔐 Security Tips

- Use strong passwords and database access restrictions
- Never commit sensitive `.env` files to a repository
- The script includes safety prompts before destructive operations


## 🤝 Contributing

Pull requests and suggestions are welcome!  
If you have ideas or questions, feel free to open an [issue](https://github.com/your-username/db-transfer/issues).
