#!/usr/bin/env roseus

;;;
;;; euslisp version of ros_tutorials/rospy_tutorials/001_talker_listener
;;;

(ros::load-ros-manifest "roseus")

;;;
(ros::roseus "talker")
(ros::advertise "leapmotion/data" std_msgs::string 1)
(ros::rate 100)
(while (ros::ok)
    (setq msg (instance std_msgs::string :init))
      (send msg :data (format nil "hello world ~a" (send (ros::time-now) :sec-nsec)))
        (ros::ros-info "msg [~A]" (send msg :data))
	  (ros::publish "leapmotion/data" msg)
	    (ros::sleep)
	      )
(ros::roseus "shutdown")
(exit)