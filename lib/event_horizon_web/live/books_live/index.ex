defmodule EventHorizonWeb.BooksLive.Index do
  use EventHorizonWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    tech_books = [
      %{
        name: "Elixir in Action",
        author: "Saša Juric",
        remark: "Great book for elixir beginners!"
      },
      %{name: "Docker in Action", author: "Jeff Nickoloff", remark: "Docker is cool!"},
      %{
        name: "Phoenix in Action",
        author: "Geoffrey Lessel",
        remark: "Nice book about phoenix and stuff. Not much about LiveView though."
      },
      %{
        name: "Programming Ecto",
        author: "Darin Wilson and Eric Meadows-Jonsson",
        remark: "Ecto is the ORM of elixir world. It's pretty neat!"
      },
      %{
        name: "Programming Phoenix LiveView",
        author: "Bruce Tate and Sophie DeBenedetto",
        remark: nil
      },
      %{
        name: "High Performace Browser Networking(hpbn.co)",
        author: "Ilya Grigorik",
        remark:
          "Most of the relevant stuff about networking. Highly recommend this book for web devs!"
      },
      %{
        name: "Concurrent Data Processing in Elixir",
        author: "Svilen Gospodinov",
        remark: "Task, GenServer, GenStage, Flow & Broadway go brrrrrrr!"
      },
      %{name: "Genetic Algorithms in Elixir", author: "Sean Moriarity", remark: nil},
      %{
        name: "Metaprogramming Elixir",
        author: "Chris McCord",
        remark: "Really love how extensible elixir is!"
      }
    ]

    fiction_books = [
      %{
        name: "Dark Matter",
        author: "Blake Crouch",
        remark: "Sci-fi, thriller. One of the first sci-fi books I read in two days!"
      },
      %{name: "Recursion", author: "Blake Crouch", remark: "Pretty recursive."},
      %{name: "Sherlock Holmes", author: "Sir Arthur Conan Doyle", remark: "The game is afoot!"},
      %{name: "Fahrenheit 451", author: "Ray Bradbury", remark: "Keep the books close."},
      %{name: "1984", author: "George Orwell", remark: "Lots of blueprint in here."},
      %{
        name: "Animal Farm",
        author: "George Orwell",
        remark: "Listen to Animals by Pink Floyd after reading this book."
      },
      %{
        name: "Project Hail Mary",
        author: "Andry Weir",
        remark: "Sci-fi, Space. Liked it very much!"
      },
      %{
        name: "The Shadow of the Wind",
        author: "Carlos Ruiz Zafón",
        remark: "Didn't expected to like this book as much as i like it now."
      },
      %{
        name: "The Stranger",
        author: "Albert Camus",
        remark:
          "Absurdism: 'a philosophy based on the belief that the universe is irrational and meaningless and that the search for order brings the individual into conflict with the universe'"
      },
      %{name: "The Book Thief", author: "Markus Zusak", remark: "Hearbreaking."},
      %{
        name: "Almond",
        author: "Won-pyung Sohn",
        remark: "Alexithymia: the inability to identify and express one's feelings."
      },
      %{name: "Sphere", author: "Michael Crichton", remark: "Insane! Don't watch the movie."},
      %{
        name: "The Three Body Problem trilogy",
        author: "Liu Cixin",
        remark: "Holy shit! The fastest I finished 3 books back to back.",
        child: ["The Three-Body Problem", "The Dark Forest", "Death's end"]
      },
      %{name: "The Bell Jar", author: "Slyvia Plath", remark: "Can write a whole essay on this."},
      %{
        name: "The Andromeda Strain",
        author: "Michael Crichton",
        remark: "I want a microscope now."
      },
      %{name: "The Vegetarian", author: "Han Kang", remark: "idk man."},
      %{
        name: "A Thousand Splendid Suns",
        author: "Khaled Hosseini",
        remark: "I am not the man I was before I picked up this book."
      },
      %{
        name: "The Metamorphosis",
        author: "Franz Kafka",
        remark: "Sometimes I do feel like the bug."
      },
      %{
        name: "Blue Sisters",
        author: "Coco Mellors",
        remark:
          "Love this. Its a story about grief, love & healing that revolves around 4 sisters."
      },
      %{
        name: "Before the Coffee Gets Cold",
        author: "Toshikazu Kawaguchi",
        remark:
          "I am peculiarly drawn towards stories of grief, regret, & love.I must read the rest of the series."
      }
    ]

    shorts = [
      %{name: "I have no mouth and I must scream", author: "Harlan Ellison"},
      %{name: "The last question", author: "Isaac Asimov"},
      %{name: "The last answer", author: "Isaac Asimov"}
    ]

    {:ok,
     socket
     |> assign(tech_books: tech_books)
     |> assign(fiction_books: fiction_books)
     |> assign(shorts: shorts)
     |> assign(page_title: "Books | Aayush Sahu")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app current_path={@current_path}>
      <h1 class="font-[Handwriting] text-4xl font-bold mb-4">Books</h1>

      <%!-- <div style={{ width: "60%", height: "auto", margin: "1rem auto" }}>
        <Image src={bookCover} alt="The Three Body Problem book cover" />
      </div> --%>

      <p class="text-(--books-paragraph)">
        List of books I have read. I'm not an avid book reader but I like to read books from time to time.
      </p>

      <h3 class="font-bold text-xl m-0">Tech</h3>
      <p class="text-(--books-paragraph)">Tech related books.</p>
      <ul>
        <li :for={book <- @tech_books} class="list-disc ml-4">
          <p class="text-lg">{book.name} by {book.author}</p>
          <p :if={book.remark} class="text-(--books-paragraph)">
            {book.remark}
          </p>
        </li>
      </ul>

      <h3 class="font-bold text-xl m-0">Fiction</h3>
      <p class="text-(--books-paragraph)">Fiction, Sci-Fi, etc.</p>
      <ul>
        <li :for={book <- @fiction_books} class="list-disc ml-4">
          <p class="text-lg">{book.name} by {book.author}</p>
          <ul :if={Map.get(book, :child)}>
            <li :for={book <- book.child} class="list-disc ml-8">
              {book}
            </li>
          </ul>
          <p :if={book.remark} class="text-(--books-paragraph)">
            {book.remark}
          </p>
        </li>
      </ul>

      <h3 class="font-bold text-xl m-0">Shorts</h3>
      <p class="text-(--books-paragraph)">Some of my favorite short stories.</p>
      <ul>
        <li :for={short <- @shorts} class="list-disc ml-4">{short.name} by {short.author}</li>
      </ul>
    </Layouts.app>
    """
  end
end
