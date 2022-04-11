
# Download
Projeto desenvolvido em Delphi e destinado a realizar download de arquivos, a partir de um endereço informado.

## Tecnologias utilizadas
- Padrão de arquitetura de software MVC
	- O MVC é utilizado em muitos projetos devido a arquitetura que possui, o que possibilita a divisão do projeto em camadas muito bem definidas. Cada uma delas, o **Model**, o **Controller** e a **View**, executa o que lhe é definido e nada mais do que isso.
	
- MultiThread 
	- A utilização de threads nas aplicações é um diferencial que traz diversas vantagens para o usuário final, uma vez que podem aumentar o desempenho da mesma. Elas permitem que as tarefas possam ser executadas em paralelo ao fluxo principal da aplicação, possibilitando assim que a mesma continue acessível ao usuário.
	
- Padrão de projeto Observer
	- O padrão de projeto **Observer** foi elaborado para permitir que objetos recebam dados ou notificações sem o conhecimento de quem é o objeto emissor. Dessa forma, alcançamos um baixo acoplamento na arquitetura, já que fortes dependências não são estabelecidas. A qualquer momento, podemos substituir o emissor ou os receptores sem prejudicar a funcionalidade existente. Pode-se dizer, portanto, que a proposta primária do _Observer_ envolve a recepção de notificações quando determinado evento ocorre em um objeto assistido.

- **SOLID**
	- **SOLID** é um acrônimo criado por [Michael Feathers](https://michaelfeathers.silvrback.com/), após observar que cinco princípios da orientação a objetos e design de código, criados por [_Robert C. Martin_](https://pt.wikipedia.org/wiki/Robert_Cecil_Martin) (a.k.a. _Uncle Bob) e abordados no artigo_ [The Principles of OOD](http://butunclebob.com/ArticleS.UncleBob.PrinciplesOfOod)  poderiam se encaixar nesta palavra.
			
		-   _**S**ingle Responsibility Principle_: Princípio da responsabilidade única;
		-   _**O**pen Closed Principle_: Princípio do aberto/fechado;
		-   _**L**iskov Substitution Principle_: Princípio da substituição de Liskov;
		-   _**I**nterface Segregation Principle:_ Princípio da segregação de  _Interfaces_;
		-   _**D**ependency Inversion Principle:_ Princípio da inversão de dependência.

## SQLite
Cada download efetivamente realizado é armazenado em uma base de dados SQLite. O arquivo (database.db), referente ao banco, se encontra na pasta: "\bin\database\".

## Compatibilidade

Download é compatível com 
- Delphi 11 Alexandria
- Delphi 10.4 Sydney
- Delphi 10.3 Rio
- Delphi 10.2 Tokyo
- Delphi 10.1 Berlin
 
## Começando

Para visualizar o projeto, será necessário instalar os seguintes programas:

- Delphi
- Gerenciador de banco de dados SQLite

## Documentação

A documentação do projeto ainda está em desenvolvimento.

## Desenvolvimento

Desenvolvido em Delphi, utilizando a base de dados SQLite.

## Construção (Build)

Para fazer o build utilize, no Delphi a combinação de teclas Shift+F9 no projeto principal.

## Testes

Não há testes disponíveis no fonte.

## Contribuições

Contribuições sempre são bem vidas e somente serão aceitas por meio dos canais oficiais.
