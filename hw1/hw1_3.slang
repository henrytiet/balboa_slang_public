import hw1_common;


void draw_circle(Shape shape, Circle circle, uint2 tid, uint height, RWTexture2D<float4> image) {
    float y = height - circle.center.y; //inversed height to match coordinate plane of hw
    float dx = tid.x - circle.center.x;
    float dy = tid.y - y;
    float dist = sqrt(dx * dx + dy * dy);
    if (dist <= circle.radius && shape.use_fill) {
        image[tid] = float4(shape.fill_rgba);
    }
    if(dist >=circle.radius - (shape.stroke_width / 2) && dist <= circle.radius + (shape.stroke_width / 2) && shape.use_stroke) {
        image[tid] = float4(shape.stroke_rgba);
    }
}

void draw_polyline(Shape shape, Polyline polyline, uint2 tid, uint height, StructuredBuffer<float2> points, RWTexture2D<float4> image) {
    // TODO: your code here    
    int numIntersects=0;
    for(int i=polyline.pts_begin;i<polyline.pts_end;i++){
        float2 p0=points[i];
        float2 p1;
        if(i==polyline.pts_end-1) {
            p1=points[polyline.pts_begin];
        } else {
            p1=points[i+1];
        }
        float p0y=height-p0.y; //inversed height to match coordinate plane of hw
        float p1y=height-p1.y;
        float dx = p1.x - p0.x; //difference of x
        float dy = p1y - p0y; //difference of y
        float t=tid.y-(p0y);

        // nonzero algorithm
        if (p0y <=tid.y && tid.y < p1y) {
            t = t / (p1y-p0y);
            if ((p0.x+t*dx) >= tid.x) {
                numIntersects++;
            }
        }
        else if (p1y <= tid.y && tid.y < p0y) {
            t= t / (p1y-p0y);
            if ((p0.x+t*dx) >= tid.x) {
                numIntersects--;
            }
        }

        
        
        
    }

    if(numIntersects!=0 && shape.use_fill){
        image[tid]=float4(shape.fill_rgba);
    }

    for(int i=polyline.pts_begin;i<polyline.pts_end;i++){
        
        if(i==polyline.pts_end-1 && !polyline.closed) break;
        float2 p0=points[i];
        float2 p1;
        if(i==polyline.pts_end-1) {
            if(polyline.closed) {
                p1=points[polyline.pts_begin];
            }
        } else {
            p1=points[i+1];
        }
        float p0y=height-p0.y; //inversed height to match coordinate plane of hw
        float p1y=height-p1.y;
        float l;
        float2 q=float2(tid.x, height-tid.y);
        float2 d = p1 - p0;
        float len = length(d);
        l=dot(d, q-p0) / len;
        float2 qprime=p0+l*d/len;
        if(l>0 && l<len && length(q-qprime) < shape.stroke_width/2.0 && shape.use_stroke) {
            image[tid]=float4(shape.stroke_rgba);
            
        }
        // round joins
        if(shape.use_stroke && (polyline.closed || i!=0)) {
            if(length(q-p0) < shape.stroke_width/2.0) {
                image[tid]=float4(shape.stroke_rgba);
            }
        }
    }

}
[shader("compute")]
[numthreads(8, 8, 1)]
void compute_main(uint2 tid : SV_DispatchThreadID,
                  uniform float3 background,
                  uniform int /*samples_per_axis*/, // ignore for now
                  StructuredBuffer<Shape> shapes,
                  uniform int num_shapes,
                  StructuredBuffer<Circle> circles,
                  StructuredBuffer<Polyline> polylines,
                  StructuredBuffer<QuadraticBezier> /*quadratic_beziers*/, // ignore for now
                  StructuredBuffer<float2> points,
                  RWTexture2D<float4> image) {
    uint width, height;
    image.GetDimensions(width, height);
    if (tid.x >= width || tid.y >= height) {
        return;
    }

    image[tid] = float4(background, 1.0);
    // TODO: your code here
    for (int i = num_shapes-1; i >= 0; i--) {
        Shape shape = shapes[i];
        if (shape.type == ShapeType.Circle) {
            draw_circle(shape, circles[shape.index], tid, height, image);
        }
        else if (shape.type == ShapeType.Polyline) {
            draw_polyline(shape, polylines[shape.index], tid, height, points, image);
        }
    }

}
