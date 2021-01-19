# mytarantool

## Запуск проекта:
Для запуска проекта выполните следующие команды:
<br>
$ git clone https://github.com/BogachevDenis/mytarantool.git
<br>
$ cd mytarantool
<br>
$ cartridge build
<br>
$ cartridge start
<br>
## Настройка приложения:
Приложение запустится на http://localhost:8081/
<br>
<li> Добавьте экземпляру tarantool "router" роль Api
<br>
<li> Добавьте экземпляру tarantool "s1-master" роль Storage
  
## Работа с приложением:

### Примеры запросов для работы с хранилищем
<li>POST Запрос на добавление новых данных
  <br>
  $ curl -X POST -v -H "Content-Type: application/json" -d '{"key":"first", "value":[{"color":"green"}]}' http://localhost:8081/kv
  <br>
 <li>PUT Запрос на изменение данных, где /first - это ключ изменяемого кортежа
  <br>
  $  curl -X PUT -v -H "Content-Type: application/json" -d '{"value":[{"color":"red"}]}' http://localhost:8081/kv/first
  <br>
 <li>GET Запрос на получение данных, где /first - это ключ получаемого кортежа
  <br>
  $  curl -X GET  http://localhost:8081/kv/first
  <br>
 <li>DELETE Запрос на удаление данных, где /first - это ключ удаляемого кортежа
  <br>
  $  curl -X DELETE  http://localhost:8081/kv/first
  <br>

