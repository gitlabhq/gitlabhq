import { BoxGeometry } from 'three/build/three.module';
import MeshObject from '~/blob/3d_viewer/mesh_object';

describe('Mesh object', () => {
  it('defaults to non-wireframe material', () => {
    const object = new MeshObject(new BoxGeometry(10, 10, 10));

    expect(object.material.wireframe).toBeFalsy();
  });

  it('changes to wirefame material', () => {
    const object = new MeshObject(new BoxGeometry(10, 10, 10));

    object.changeMaterial('wireframe');

    expect(object.material.wireframe).toBeTruthy();
  });

  it('scales object down', () => {
    const object = new MeshObject(new BoxGeometry(10, 10, 10));
    const { radius } = object.geometry.boundingSphere;

    expect(radius).not.toBeGreaterThan(4);
  });

  it('does not scale object down', () => {
    const object = new MeshObject(new BoxGeometry(1, 1, 1));
    const { radius } = object.geometry.boundingSphere;

    expect(radius).toBeLessThan(1);
  });
});
