-- Flusso
-- MoneyMoney Export Extension
-- Exports booked transactions as JSON for sync to YNAB via sync.sh.

Exporter {
  version       = 1.2,
  format        = "Flusso – Export for YNAB",
  fileExtension = "json",
  description   = "Exports transactions as JSON for YNAB sync."
}

-- ============================================================
-- HELPERS
-- ============================================================

local function formatDate(timestamp)
  return os.date("%Y-%m-%d", timestamp)
end

local function toMilliunits(amount)
  return math.floor(amount * 1000)
end

local function jsonEscape(s)
  if not s then return "" end
  return s:gsub('\\', '\\\\'):gsub('"', '\\"'):gsub('\n', '\\n')
end

-- ============================================================
-- MONEYMONEY EXPORT HOOKS
-- ============================================================

local isFirst = true

function WriteHeader(account, startDate, endDate, transactionCount)
  assert(io.write('{\n'))
  assert(io.write('  "account_name": "' .. jsonEscape(account.name) .. '",\n'))
  assert(io.write('  "account_number": "' .. jsonEscape(account.accountNumber or account.iban or "") .. '",\n'))
  assert(io.write('  "export_date": "' .. os.date("%Y-%m-%d") .. '",\n'))
  assert(io.write('  "transactions": [\n'))
  isFirst = true
end

function WriteTail(account)
  assert(io.write('\n  ]\n}\n'))
end

-- ============================================================
-- MAIN EXPORT FUNCTION
-- ============================================================

function WriteTransactions(account, transactions)
  for _, tx in ipairs(transactions) do
    if tx.booked then
      if not isFirst then
        assert(io.write(',\n'))
      end
      isFirst = false

      local line = string.format(
        '    {"id":%d,"date":"%s","amount":%d,"payee_name":"%s","memo":"%s","booked":%s}',
        tx.id,
        formatDate(tx.bookingDate),
        toMilliunits(tx.amount),
        jsonEscape(tx.name or "Unknown"),
        jsonEscape(tx.purpose or ""),
        tostring(tx.booked)
      )
      assert(io.write(line))
    end
  end
end
