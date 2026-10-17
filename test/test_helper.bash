# Shared setup for flusso tests: isolated HOME, fake osascript/curl on PATH,
# and builders for MoneyMoney and YNAB fixtures.
#
# macOS runs bats under bash 3.2, where a failing `[[ ]]` doesn't fail the test
# unless it's the last line. Always write `[[ ... ]] || false`.

FLUSSO="$BATS_TEST_DIRNAME/../flusso"
SYNC_CATEGORY_UUID="11111111-2222-3333-4444-555555555555"
BUDGET_ID="budget-1"
YNAB_CHECKING="ynab-checking"
YNAB_BROKERAGE="ynab-brokerage"
# Account Mapping of a Brokerage Account in Balance Sync
BROKERAGE_MAPPING="{\"name\": \"Brokerage\", \"moneymoney_account\": \"123456789\", \"ynab_account_id\": \"$YNAB_BROKERAGE\", \"mode\": \"balance\"}"

setup() {
  export HOME="$BATS_TEST_TMPDIR/home"
  export FAKE_DIR="$BATS_TEST_TMPDIR/fake"
  export TMPDIR="$BATS_TEST_TMPDIR/tmp"
  mkdir -p "$HOME/.flusso" "$FAKE_DIR/mm" "$FAKE_DIR/ynab" "$TMPDIR"
  : > "$FAKE_DIR/osascript.log"
  : > "$FAKE_DIR/curl.log"
  : > "$FAKE_DIR/ynab/routes"
  export PATH="$BATS_TEST_DIRNAME/fakes:$PATH"
}

# ── Config ──────────────────────────────────────────────────

# write_config [ACCOUNTS_JSON] [EXTRA_JSON]
# Default: one Account Mapping "Checking" (DE001 → $YNAB_CHECKING, Transaction Sync).
write_config() {
  local accounts="${1:-}" extra="${2:-}"
  [ -n "$accounts" ] || accounts="[{\"name\": \"Checking\", \"moneymoney_account\": \"DE001\", \"ynab_account_id\": \"$YNAB_CHECKING\"}]"
  [ -n "$extra" ] || extra='{}'
  jq -n \
    --arg budget "$BUDGET_ID" \
    --arg cat "$SYNC_CATEGORY_UUID" \
    --argjson accounts "$accounts" \
    --argjson extra "$extra" \
    '{api_token: "test-token", budget_id: $budget, start_date: "2026-04-01",
      sync_category: {uuid: $cat, name: "YNAB Synced"}, accounts: $accounts} + $extra' \
    > "$HOME/.flusso/config.json"
  chmod 600 "$HOME/.flusso/config.json"
}

# ── MoneyMoney fixtures ─────────────────────────────────────

# mm_tx ID DATE AMOUNT BOOKED CATEGORY_UUID NAME PURPOSE
# Prints one transaction <dict> as MoneyMoney's plist export does.
mm_tx() {
  local id="$1" date="$2" amount="$3" booked="$4"
  local category name purpose
  category=$(xml_escape "$5"); name=$(xml_escape "$6"); purpose=$(xml_escape "$7")
  cat <<EOF
		<dict>
			<key>accountUuid</key>
			<string>aaaaaaaa-0000-0000-0000-000000000001</string>
			<key>amount</key>
			<real>$amount</real>
			<key>booked</key>
			<$booked/>
			<key>bookingDate</key>
			<date>${date}T00:00:00Z</date>
			<key>categoryUuid</key>
			<string>$category</string>
			<key>currency</key>
			<string>EUR</string>
			<key>id</key>
			<integer>$id</integer>
			<key>name</key>
			<string>$name</string>
			<key>purpose</key>
			<string>$purpose</string>
			<key>valueDate</key>
			<date>${date}T00:00:00Z</date>
		</dict>
EOF
}

xml_escape() {
  printf '%s' "$1" | sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g'
}

# mm_has_transactions [MONEYMONEY_ACCOUNT] < TX_DICTS
# Serves the given transaction dicts for "export transactions" of that
# MoneyMoney Account, or of every account if none is given.
mm_has_transactions() {
  { echo "<dict><key>creator</key><string>MoneyMoney</string><key>transactions</key><array>"
    cat
    echo "</array></dict>"
  } | plist_document > "$FAKE_DIR/mm/export-transactions${1:+-$1}.plist"
}

# mm_has_single_transaction < TX_DICT
# Serves an export whose transactions value is one dict instead of an array.
mm_has_single_transaction() {
  { echo "<dict><key>creator</key><string>MoneyMoney</string><key>transactions</key>"
    cat
    echo "</dict>"
  } | plist_document > "$FAKE_DIR/mm/export-transactions.plist"
}

# mm_export_is_garbled [MONEYMONEY_ACCOUNT]
# Serves an "export transactions" response that isn't a valid plist.
mm_export_is_garbled() {
  echo "<plist><dict><key>transactions" > "$FAKE_DIR/mm/export-transactions${1:+-$1}.plist"
}

# mm_account NUMBER BALANCE PORTFOLIO
# Prints one account <dict> as MoneyMoney's "export accounts" does (with icon blob).
mm_account() {
  cat <<EOF
	<dict>
		<key>accountNumber</key>
		<string>$1</string>
		<key>balance</key>
		<array>
			<array>
				<real>$2</real>
				<string>EUR</string>
			</array>
		</array>
		<key>group</key>
		<false/>
		<key>icon</key>
		<data>
		iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk
		</data>
		<key>name</key>
		<string>Account $1</string>
		<key>portfolio</key>
		<$3/>
		<key>refreshTimestamp</key>
		<date>2026-04-05T08:00:00Z</date>
	</dict>
EOF
}

# mm_has_accounts < ACCOUNT_DICTS
# Serves the given account dicts for "export accounts".
mm_has_accounts() {
  { echo "<array>"; cat; echo "</array>"; } | plist_document > "$FAKE_DIR/mm/export-accounts.plist"
}

# mm_category NAME UUID [GROUP]
# Prints one category <dict> as MoneyMoney's "export categories" does (with icon blob).
mm_category() {
  cat <<EOF
	<dict>
		<key>group</key>
		<${3:-false}/>
		<key>icon</key>
		<data>
		iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk
		</data>
		<key>name</key>
		<string>$(xml_escape "$1")</string>
		<key>uuid</key>
		<string>$2</string>
	</dict>
EOF
}

# mm_has_categories < CATEGORY_DICTS
# Serves the given category dicts for "export categories".
mm_has_categories() {
  { echo "<array>"; cat; echo "</array>"; } | plist_document > "$FAKE_DIR/mm/export-categories.plist"
}

# plist_document < PLIST_VALUE
# Wraps a plist value in the XML prolog MoneyMoney's exports start with.
plist_document() {
  cat <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
EOF
  cat
  echo "</plist>"
}

# ── YNAB fixtures ───────────────────────────────────────────

# ynab_route METHOD PATH JSON
# Serves JSON for METHOD PATH (path relative to /v1, without query string).
ynab_route() {
  local file="$FAKE_DIR/ynab/response-$(wc -l < "$FAKE_DIR/ynab/routes" | tr -d ' ').json"
  printf '%s' "$3" > "$file"
  echo "$1 $2 $file" >> "$FAKE_DIR/ynab/routes"
}

# ynab_accepts_transactions [CREATED_COUNT] [DUPLICATE_COUNT]
ynab_accepts_transactions() {
  local created="${1:-1}" duplicates="${2:-0}"
  ynab_route POST "/budgets/$BUDGET_ID/transactions" "$(jq -cn \
    --argjson c "$created" --argjson d "$duplicates" \
    '{data: {transaction_ids: [range($c) | "ynab-tx-\(.)"], duplicate_import_ids: [range($d) | "dup-\(.)"]}}')"
}

# ynab_has_transactions ACCOUNT_ID JSON_ARRAY
# Serves the YNAB Account's existing transactions.
ynab_has_transactions() {
  ynab_route GET "/budgets/$BUDGET_ID/accounts/$1/transactions" "{\"data\": {\"transactions\": $2}}"
}

# ynab_has_balance ACCOUNT_ID MILLIUNITS
# Serves the YNAB Account with the given balance.
ynab_has_balance() {
  ynab_route GET "/budgets/$BUDGET_ID/accounts/$1" "{\"data\": {\"account\": {\"id\": \"$1\", \"balance\": $2}}}"
}

# ynab_has_budget
# Serves a valid token, one budget "My Budget" ($BUDGET_ID) and its YNAB Accounts:
# [1] Checking ($YNAB_CHECKING), [2] Brokerage ($YNAB_BROKERAGE), plus a closed one.
ynab_has_budget() {
  ynab_route GET /user '{"data": {"user": {"id": "user-1"}}}'
  ynab_route GET /budgets "{\"data\": {\"budgets\": [{\"id\": \"$BUDGET_ID\", \"name\": \"My Budget\"}]}}"
  ynab_route GET "/budgets/$BUDGET_ID/accounts" "{\"data\": {\"accounts\": [
    {\"id\": \"$YNAB_CHECKING\", \"name\": \"Checking\", \"closed\": false, \"balance\": 1250000},
    {\"id\": \"ynab-old\", \"name\": \"Old Account\", \"closed\": true, \"balance\": 0},
    {\"id\": \"$YNAB_BROKERAGE\", \"name\": \"Brokerage\", \"closed\": false, \"balance\": 10000000}
  ]}}"
}

# setup_fixtures
# Everything setup needs: the YNAB budget and the MoneyMoney categories
# [1] Groceries, [2] YNAB Synced (Sync Category), plus a category group.
setup_fixtures() {
  ynab_has_budget
  {
    mm_category "Everyday" group-1 true
    mm_category "Groceries" cat-groceries
    mm_category "YNAB Synced" "$SYNC_CATEGORY_UUID"
  } | mm_has_categories
}

# ── Answers for interactive commands ────────────────────────

# transaction_mapping_answers NAME NUMBER YNAB_INDEX [START_DATE]
# Answers for one Account Mapping in Transaction Sync, accepting the default mode.
transaction_mapping_answers() {
  printf '%s\n' "$1" "$2" "" "${4:-}" "$3"
}

# balance_mapping_answers NAME NUMBER YNAB_INDEX
# Answers for one Account Mapping of a Brokerage Account, accepting the
# pre-selected Balance Sync (which asks no start date).
balance_mapping_answers() {
  printf '%s\n' "$1" "$2" "" "$3"
}

# setup_answers TOKEN START_DATE CATEGORY_INDEX MAPPING_ANSWERS_COMMAND...
# Answers for a full setup with budget [1] and one Account Mapping.
setup_answers() {
  local token="$1" start_date="$2" category="$3"
  shift 3
  printf '%s\n' "$token" 1 "$start_date"
  "$@"
  printf '%s\n' n "$category"
}

# ── Call logs ───────────────────────────────────────────────

# MoneyMoney Accounts whose transactions were exported, one per line.
exported_accounts() {
  transaction_exports | cut -d ' ' -f 1
}

# Transaction exports requested from MoneyMoney, as "ACCOUNT START_DATE" lines.
transaction_exports() {
  jq -r 'select(.command == "export-transactions") | .args | join(" ")' "$FAKE_DIR/osascript.log"
}

# All requests sent to YNAB, as one JSON array.
ynab_requests() {
  jq -s '.' "$FAKE_DIR/curl.log"
}

# Transactions posted to YNAB, as one JSON array across all POSTs.
posted_transactions() {
  jq -s '[.[] | select(.method == "POST") | .body.transactions // [.body.transaction] | .[]]' "$FAKE_DIR/curl.log"
}

# MoneyMoney transaction ids marked with the Sync Category, one per line.
marked_as_synced() {
  jq -r --arg cat "$SYNC_CATEGORY_UUID" \
    'select(.command == "set-transaction" and .category == $cat) | .id' "$FAKE_DIR/osascript.log"
}
