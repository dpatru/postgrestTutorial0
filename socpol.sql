
-- create a named schema
create schema api;

-- create the todos table
create table api.todos (
  id serial primary key,
  done boolean not null default false,
  task text not null,
  due timestamptz
);

insert into api.todos (task) values
  ('finish tutorial 0'), ('pat self on back');


create table api.relations (
  relation text not null,
  x int,
  y int,
  text text,
  ts timestamptz
  );
  

insert into api.relations (relation, x, text) values
  ('task', 1, 'task 1'), ('id', 2, 'task 2');

insert into api.relations (relation, x, y) values
  ('est-hours', 1, 3), ('est-hours', 2, 4);

insert into api.relations (relation, x, y) values
  ('before', 1, 2);

-- create a role to use for anonymous web requests.
create role web_anon nologin;
grant usage on schema api to web_anon;
grant select on api.todos to web_anon;

-- create authenticator role
create role authenticator noinherit login password 'mysecretpassword';
grant web_anon to authenticator;

-- add trusted user
create role todo_user nologin;
grant todo_user to authenticator;
grant usage on schema api to todo_user;
grant all on api.todos to todo_user;
grant usage, select on sequence api.todos_id_seq to todo_user;

select extract(epoch from now() + '5 minutes'::interval) :: integer;


-- Bonus Topic: Immediate Revocation

create schema auth;
grant usage on schema auth to web_anon, todo_user;
create or replace function auth.check_token() returns void
  language plpgsql
  as $$
begin
  if current_setting('request.jwt.claim.email', true) =
    'disgruntled@mycompany.com' then
    raise insufficient_privilege
      using hint = 'Nope, we are on to you';
  end if;
end
$$;
