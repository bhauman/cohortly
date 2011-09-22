Cohortly::TagConfig.draw_tags do
  
  tag :hello do
    controller :hi_there do
      actions :index, :create, :update
    end
  end

  tag :goodbye do
    controller :see_ya do
      actions :create, :update
    end
    controller :hi_there do
      actions :update
    end
  end

  tag :only_good do
    controllers :stuff, :goodies
  end

  tag :only_bad do
    controllers :stuff, :goodies
  end

  tags :heh, :whoa do
    controllers :hellas
  end

  tag :over13 do
    controller :session do
      actions :login
    end
  end
  tag :login do
    controller :session do
      actions :login
    end
  end
end