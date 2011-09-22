Cohortly::TagConfig.draw_tags do
      tag :hey do
       controllers :stuff
      end
      tag :my do
        controller :stuff do
          actions :my_stuff
        end
      end
      tag :your do
        controller :stuff do
          actions :your_stuff
        end
      end
    end