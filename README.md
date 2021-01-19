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
<li> Добавьте экземляру tarantool "router" роль Api
<br>
<li> Добавьте экземляру tarantool "s1-master" роль Storage
  
## Работа с приложением:

### Запросы для работы с хранилище
<li>POST Запрос на добавление новых данных
  <br>
  $ curl -X POST -v -H "Content-Type: application/json" -d '{"key":"first", "value":[{"red":"green"}]}' http://localhost:8081/kv
  

