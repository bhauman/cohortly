Cohortly::TagConfig.draw_tags do
  groups :rand_0, :rand_1, :rand_3
   
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
