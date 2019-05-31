# Tutorial 0
sudo docker run --name tutorial -p 5433:5432 \
                -e POSTGRES_PASSWORD=mysecretpassword \
                -d postgres

# connect, see https://stackoverflow.com/questions/6523019/postgresql-scripting-psql-execution-with-password
PGPASSWORD=mysecretpassword psql --host=localhost --port=5433 --username=postgres
 
./postgrest tutorial.conf &

curl http://localhost:3000/todos

curl http://localhost:3000/todos -X POST -H "Content-Type: application/json" -d '{"task": "do bad thing"}'

# Tutorial 1

# Allow "tr" to process non-utf8 byte sequences
export LC_CTYPE=C

# read random bytes and keep only alphanumerics
< /dev/urandom tr -dc A-Za-z0-9 | head -c32

export secret="hmZVOiLNt4ymekZCZy55JQb7D3Q2qo2k" # < /dev/urandom tr -dc A-Za-z0-9 | head -c32

export TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoidG9kb191c2VyIn0.5Tj38HXdt8NpJF5Kk7kKLak27tvzEVC98c6gb4mnI2M"

curl http://localhost:3000/todos -X POST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -d '{"task": "learn how to auth"}'

curl http://localhost:3000/todos -X PATCH -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -d '{"done": true}'



