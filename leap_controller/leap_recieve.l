 #!/usr/bin/env roseus
;;;
;;; euslisp version of ros_tutorials/rospy_tutorials/001_talker_listener
;;;

(ros::load-ros-manifest "roseus")
(ros::load-ros-manifest "leap_control")

(ros::roseus "leap_listener")

(defclass string-cb-class
  :super propertied-object
  :slots ())
(defmethod string-cb-class
  (:init () (ros::subscribe "leapmotion/data" leap_control::leapros #'send self :string-cb))
					; kokomade
					;date ->direction nanikak
   (:string-cb (msg) 
	       (setq hand_poss (send msg :points))
	       (setq hand_points3D nil)
	       (setq hand_points3D_r nil)
	       (let ((x 0))
		 (dolist (pos hand_poss)
		   (setq hand_points3D (append hand_points3D (list (float-vector (* -5 (send pos :x)) (* 5 (send pos :z)) (* 5 (+ (send pos :y) -90))))))
		   (send (elt cube_hands x) :locate (float-vector (* -5 (send pos :x)) (* 5 (send pos :z)) (* 5 (+ (send pos :y) -90))) :worldpos)		  
		   (setq hand_points3D_r (append hand_points3D (list (float-vector (* -1.4 (- (send pos :x) 200)) (* 1.4 (send pos :z)) (* 1.4 (+ (send pos :y) -300))))))
		   (send (elt cube_hands_r x) :locate (float-vector (* -1.4 (- (send pos :x) 200)) (* 1.4 (send pos :z)) (* 1.4 (+ (send pos :y) -300))) :worldpos)
		   (setq x (+ x 1))
		   )
		 (while (> 10 x)
		   (send (elt cube_hands x) :locate #f(0 0 0) :worldpos)
		   (send (elt cube_hands_r x) :locate #f(1000 0 0) :worldpos)
		   (setq x (+ x 1))
		   )
		 )
	        
	       (format t "get data\n")
	       (setq avoid_point nil)

					;(setq arm :larm) 
	       (setq det_pos1 x_r1)
	       (dolist (hand_pos hand_points3D_r)
		 (setq dif (v- hand_pos x_r1))
		 (if (< (v. dif dif) 3000)		   
		       (progn
			 (setq det_pos1 (v+ det_pos1 (scale 0.1 dif))) ;kokode minus mo ireru 	
			 )
		   )
		 )
	       (setq det_pos2 x_r2)
	       (dolist (hand_pos hand_points3D_r)
		 (setq dif (v- hand_pos x_r2))
		 (if (< (v. dif dif) 3000)		   
		       (progn
			 (setq det_pos2 (v+ det_pos2 (scale 0.2 dif))) ;kokode minus mo ireru 	
			 )
		   )
		 )
	       (setq dif (v- det_pos1 det_pos2))
	       (setq dif_n (v. dif dif))
	       (if grip_r 
		   (if (> dif_n 10000)
		       (progn
			 (setq grip_r nil)
			 (send *ri* :stop-grasp)
			 (setq scaler (* 0.000005 (- dif_n 10000)))			   
			 )
		     (progn 
		       (setq scaler (* 0.000005 (- dif_n 6000)))			   
		       )
		     )
		 (if (< dif_n 4000)
		     (progn
		       (setq grip_r t)
		       (send *ri* :start-grasp)
		       (setq scaler (* 0.000005 (- dif_n 6000)))			   
		       )
		   (progn 
		     (setq scaler (* 0.000005 (- dif_n 10000)))			   
		     )
		   )
		 )
	       (print grip_r)
       	       (setq det_pos2 (v+ det_pos2 (scale scaler dif)))
;	       (setq x_r1 det_pos1)
	       (setq x_r1 (scale 100 (normalize-vector x_r1)))
	       (send cube_r1 :locate  x_r1 :world_pos)
	       (setq x_r2 det_pos2)
	       (setq x_r2 (scale 140 (normalize-vector x_r2)))
	       (send cube_r2 :locate  x_r2 :world_pos)
			    
 	       
	       (dolist (arm '(:rarm :larm))  
					;(setq arm :larm) 
		 (setq temp_pos (send (send *pr2* arm :end-coords) :worldpos))
		 (setq det_pos temp_pos)
		 (setq avoid_point (append avoid_point (list temp_pos)))
		 (dolist (hand_pos hand_points3D)
		   (setq dif (v- hand_pos temp_pos))
		   (if (< (v. dif dif) 100000)		   
		       (progn
			 (setq det_pos (v+ det_pos (scale 0.1 dif))) ;kokode minus mo ireru 	
			 )
		     )
		   )
		 (dolist (hand_pos avoid_point)
		   (setq dif (v- hand_pos temp_pos))
		   (if (< (v. dif dif) 100000)		   
		       (progn
			 (setq det_pos (v+ det_pos (scale -0.2 dif))) ;kokode minus mo ireru 	
			 )
		     )
		   )
		 (if (equal arm :rarm)
		     (send *pr2* arm :inverse-kinematics 
			   (make-cascoords :pos det_pos :rot 
					   (inverse-matrix
					    (make-matrix 3 3 (list 			
							     
;							     #f(1 0 0) #f(0 1 0) #f(0 0 1)
							     (normalize-vector  (scale 1 x_r1)) 
							     (normalize-vector (v- x_r1 x_r2))
							     (normalize-vector (v* x_r1 (v- x_r1 x_r2)))
;#f(0 -1 0) #f(0 0 -1)
	
							     ))
					   )
					   )
			   :revert-if-fail nil :stop 10 :rotation-axis t)  
		   )
		 (if (equal arm :larm)
		     (send *pr2* arm :inverse-kinematics (make-cascoords :pos det_pos) :revert-if-fail nil :stop 10 :rotation-axis t) 
		   )
		 )
	        (if (eq counter 200) 
		   (progn 
		     (format t "before send *ri* ")
		     ;(send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
					;(send *ri* :angle-vector-sequence (list (send *pr2* :angle-vector)) (list 1000))
					;	     (send *ri* :wait-interpolation)
		     (format t "after send *ri* ")
		     (setq counter 0)
		     
		     )
		 )
	       
	       (send viewer :draw-objects)
	       (send viewer_r :draw-objects)
	       (x::window-main-one)

	       (setq counter (1+ counter))


	       )
   )

(load "package://pr2eus/pr2-interface.l")
(pr2)
(pr2-init)

(send *pr2* :init-pose)
(send *ri* :angle-vector (send *pr2* :angle-vector))
(send *ri* :wait-interpolation)
(setq counter 0)
(setq cube_hands nil)
(setq cube_hands_r nil)
(dotimes (x 10) (setq cube_hands (append cube_hands (list (make-cube 100 100 100)))))
(dotimes (x 10) (send (elt cube_hands x) :set-color :red))
(dotimes (x 10) (setq cube_hands_r (append cube_hands_r (list (make-cube 20 20 20)))))
(dotimes (x 10) (send (elt cube_hands_r x) :set-color :red))

(setq grip_r nil)
(setq cube_r1 (make-cube 20 20 20))
(send cube_r1 :set-color :green)
(setq x_r1 #f(100.0 0 0))
(send cube_r1 :locate  x_r1 :world_pos)

(setq cube_r2 (make-cube 20 20 20))
(send cube_r2 :set-color :yellow)
(setq x_r2 #f(80.0 -55 0))
(send cube_r2 :locate  x_r2 :world_pos)

(setq viewer_r (make-irtviewer))
(setq viewer (make-irtviewer))
(send viewer :resize 1000 1000)
(send viewer :objects (cons *pr2* cube_hands))
(send viewer_r :objects (cons cube_r1 (cons cube_r2 cube_hands_r)))
(send viewer :look-all)
(setq m (instance string-cb-class :init))

(defun sending ()
  (do-until-key
    (send *ri* :angle-vector (send *pr2* :angle-vector) 1000)
;    (send *ri* :wait-interpolation)
    (unix:sleep 1000)
))
;(sys::make-thread 2)
;(sys::thread-no-wait #'sending )

(do-until-key
  (ros::spin-once)
  ;;(sys::gc)
)
 ;(ros::spin)
